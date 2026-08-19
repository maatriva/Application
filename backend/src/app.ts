import express, { Response } from 'express';
import http from 'http';
import path from 'path';
import fs from 'fs';
import { env } from './config/env';
import { prisma } from './config/database';
import { getMusicUploadsDirectory, getBgmUploadsDirectory, getRecordingsUploadsDirectory } from './config/uploads.config';
import { MusicService } from './modules/music/music.service';
import { AlertEngine } from './services/alertEngine';
import { MqttClientManager } from './mqtt/mqttClient';
import { WebsocketServerManager } from './websocket/websocketServer';
import { errorHandler } from './middleware/error.middleware';
import { requestIdMiddleware, RequestWithId } from './middleware/requestId.middleware';
import { Logger } from './utils/logger';
import apiRouter from './routes';
import { authenticateToken, AuthenticatedRequest } from './middleware/auth.middleware';

import helmet from 'helmet';
import { corsMiddleware } from './middleware/cors.middleware';
import { generalApiLimiter } from './middleware/rateLimiter.middleware';

async function startServer() {
  const app = express();

  if (env.TRUST_PROXY) {
    app.set('trust proxy', 1);
  }

  // 1. Request Tracing ID Middleware
  app.use(requestIdMiddleware);

  // 2. Helmet Security Headers (HSTS enabled in production only)
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      hsts: env.NODE_ENV === 'production' ? { maxAge: 31536000, includeSubDomains: true } : false,
    })
  );

  // 3. CORS Middleware
  app.use(corsMiddleware);

  // 4. General API Rate Limiter
  app.use(generalApiLimiter);

  // 5. Request Body Size Limits (2MB default)
  app.use(express.json({ limit: env.JSON_BODY_LIMIT }));
  app.use(express.urlencoded({ limit: env.URLENCODED_BODY_LIMIT, extended: true }));

  const musicDirectory = getMusicUploadsDirectory();
  const bgmDirectory = getBgmUploadsDirectory();
  const recordingsDirectory = getRecordingsUploadsDirectory();

  Logger.info(`[Static] Serving public /uploads/music & /uploads/bgm from disk`);
  app.use('/uploads/music', express.static(musicDirectory, {
    setHeaders: (res) => {
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    }
  }));
  app.use('/uploads/bgm', express.static(bgmDirectory, {
    setHeaders: (res) => {
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    }
  }));

  // Protected Private Recordings Endpoint
  app.get('/uploads/recordings/:filename', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized.' });
    }

    const filename = req.params.filename;
    if (!filename || filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
      return res.status(400).json({ success: false, error: 'Invalid recording filename.' });
    }

    const filePath = path.join(recordingsDirectory, filename);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ success: false, error: 'Recording file not found.' });
    }

    const targetUrl = `/uploads/recordings/${filename}`;
    const track = await prisma.musicTrack.findFirst({
      where: { storageUrl: targetUrl },
    });

    if (track && track.uploadedBy && track.uploadedBy !== userId) {
      const hasCaregiverShare = await prisma.temporaryCaregiverPermission.findFirst({
        where: {
          caregiverId: userId,
          status: 'ACTIVE',
          revoked: false,
          expiresAt: { gt: new Date() },
        },
      });
      if (!hasCaregiverShare) {
        return res.status(403).json({ success: false, error: 'Access denied to private recording.' });
      }
    }

    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('Content-Type', 'audio/mpeg');
    return res.sendFile(filePath);
  });

  // Safe operational HTTP request logger middleware
  app.use((req: RequestWithId, res, next) => {
    Logger.info(`[HTTP] ${req.method} ${req.path}`, {
      requestId: req.requestId,
      method: req.method,
      path: req.path,
    });
    next();
  });

  const server = http.createServer(app);

  // 1. Verify Prisma / PostgreSQL connection & Sync Disk Uploads
  try {
    await prisma.$queryRaw`SELECT 1`;
    Logger.info('✓ PostgreSQL connected');
    Logger.info('✓ Prisma connected');
    const syncedCount = await MusicService.syncDiskUploads();
    Logger.info(`✓ Startup scan completed: ${syncedCount} missing songs synced into catalog database.`);
  } catch (e) {
    Logger.error('PostgreSQL / Prisma connection failed:', { error: e });
    process.exit(1);
  }

  // 2. Initialize Real-Time WebSocket Server
  const wsManager = WebsocketServerManager.getInstance();
  wsManager.initialize(server);

  // 3. Initialize Alert Engine
  const alertEngine = new AlertEngine();
  alertEngine.onAlertTriggered = (alert) => {
    Logger.info(`Alert triggered: [${alert.severity?.toUpperCase()}] ${alert.message}`);
    if (alert.babyId) {
      wsManager.broadcastAlert(alert.babyId, alert);
    }
  };

  // 4. Initialize MQTT Telemetry Ingestion client
  const mqttManager = new MqttClientManager(alertEngine);
  mqttManager.connect();

  // 5. Register Routes (Canonical /api base path & root fallback)
  app.use('/api', apiRouter);
  app.use('/', apiRouter);

  // GET /health/liveness & /api/health/liveness (Liveness Probe - process is running)
  app.get(['/health/liveness', '/api/health/liveness'], (_req, res) => {
    return res.status(200).json({
      status: 'ALIVE',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
    });
  });

  // GET /health/readiness & /api/health/readiness (Readiness Probe - process + DB + dependencies ready)
  app.get(['/health/readiness', '/api/health/readiness'], async (_req, res) => {
    let dbStatus = 'disconnected';
    let isHealthy = false;
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbStatus = 'connected';
      isHealthy = true;
    } catch {
      dbStatus = 'error';
      isHealthy = false;
    }

    const statusCode = isHealthy ? 200 : 503;
    return res.status(statusCode).json({
      status: isHealthy ? 'READY' : 'NOT_READY',
      timestamp: new Date().toISOString(),
      database: dbStatus,
      mqtt: mqttManager.getStatus(),
    });
  });

  // GET /health & /api/health endpoints (Unified Operational Health Check - bypasses rate limiter & authentication)
  app.get(['/health', '/api/health'], async (_req, res) => {
    let dbStatus = 'disconnected';
    let isHealthy = false;
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbStatus = 'connected';
      isHealthy = true;
    } catch {
      dbStatus = 'error';
      isHealthy = false;
    }

    const statusCode = isHealthy ? 200 : 503;
    const mem = process.memoryUsage();

    return res.status(statusCode).json({
      status: isHealthy ? 'OK' : 'DEGRADED',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
      database: dbStatus,
      mqtt: mqttManager.getStatus(),
      memoryUsage: {
        rssMb: Math.round(mem.rss / (1024 * 1024)),
        heapUsedMb: Math.round(mem.heapUsed / (1024 * 1024)),
      },
    });
  });

  // 404 Handler for unmatched routes
  app.use((req, res) => {
    res.status(404).json({
      success: false,
      message: `Cannot ${req.method} ${req.path}`,
    });
  });

  // Global Error Handler
  app.use(errorHandler);

  server.listen(env.PORT, env.HOST, () => {
    Logger.info(`✓ Express running on port ${env.PORT} (bound to ${env.HOST})`);
    Logger.info(`MAATRIVA Backend Server running at http://${env.HOST}:${env.PORT}`);
  });
}

// Handle unexpected shutdowns
const gracefulShutdown = (signal: string) => {
  Logger.info(`${signal} signal received. Cleaning resources and shutting down...`);
  prisma.$disconnect();
  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

startServer().catch((err) => {
  Logger.error('Server startup crash:', { error: err });
});
