import express from 'express';
import http from 'http';
import { env } from './config/env';
import { prisma } from './config/database';
import { getUploadsDirectory } from './config/uploads.config';
import { MusicService } from './modules/music/music.service';
import { AlertEngine } from './services/alertEngine';
import { MqttClientManager } from './mqtt/mqttClient';
import { WebsocketServerManager } from './websocket/websocketServer';
import { errorHandler } from './middleware/error.middleware';
import apiRouter from './routes';

import path from 'path';

async function startServer() {
  const app = express();

  // 1. CORS Middleware setup - Must be executed first for all routes & static assets
  app.use((req, res, next) => {
    const origin = req.headers.origin;
    if (origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    } else {
      res.setHeader('Access-Control-Allow-Origin', '*');
    }
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Access-Control-Allow-Request-Private-Network, *');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Private-Network', 'true');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');

    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    next();
  });

  app.use(express.json({ limit: '100mb' }));
  app.use(express.urlencoded({ limit: '100mb', extended: true }));
  const uploadsDirectory = getUploadsDirectory();
  console.log(`[Static] Serving /uploads from disk path: ${uploadsDirectory}`);
  app.use('/uploads', express.static(uploadsDirectory, {
    setHeaders: (res) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', '*');
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    }
  }));

  // Request logger middleware
  app.use((req, res, next) => {
    console.log(`[HTTP] ${req.method} ${req.url}`);
    if (req.method !== 'GET' && req.body) {
      console.log('Body:', JSON.stringify(req.body, null, 2));
    }
    next();
  });

  const server = http.createServer(app);

  // 1. Verify Prisma / PostgreSQL connection & Ensure Admin User & Sync Disk Uploads
  try {
    await prisma.$queryRaw`SELECT 1`;
    console.log('✓ PostgreSQL connected');
    console.log('✓ Prisma connected');
    const { AuthService } = await import('./modules/auth/auth.service');
    await AuthService.ensureAdminAccount();
    const syncedCount = await MusicService.syncDiskUploads();
    console.log(`✓ Startup scan completed: ${syncedCount} missing songs synced into catalog database.`);
  } catch (e) {
    console.error('PostgreSQL / Prisma connection failed:', e);
    process.exit(1);
  }

  // 2. Initialize Real-Time WebSocket Server
  const wsManager = WebsocketServerManager.getInstance();
  wsManager.initialize(server);

  // 3. Initialize Alert Engine
  const alertEngine = new AlertEngine();
  alertEngine.onAlertTriggered = (alert) => {
    console.log(`Alert triggered: [${alert.severity.toUpperCase()}] ${alert.message}`);
    if (alert.babyId) {
      wsManager.broadcastAlert(alert.babyId, alert);
    }
  };

  // 4. Initialize MQTT Telemetry Ingestion client
  const mqttManager = new MqttClientManager(alertEngine);
  mqttManager.connect();

  // 5. Register Routes
  app.use('/api', apiRouter);
  app.use('/', apiRouter);

  // GET /health endpoint
  app.get('/health', async (req, res) => {
    let dbStatus = 'disconnected';
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbStatus = 'connected';
    } catch {
      dbStatus = 'error';
    }

    res.json({
      status: 'OK',
      database: dbStatus,
      mqtt: 'connected', // Since MQTT auto-reconnects and is connected asynchronously
      server: 'running',
    });
  });

  // Global Error Handler
  app.use(errorHandler);

  server.listen(env.PORT, env.HOST, () => {
    console.log(`✓ Express running on port ${env.PORT} (bound to ${env.HOST})`);
    console.log(`MAATRIVA Backend Server running at http://${env.HOST}:${env.PORT}`);
  });
}

// Handle unexpected shutdowns
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received. Cleaning resources and shutting down...');
  prisma.$disconnect();
  process.exit(0);
});

startServer().catch((err) => {
  console.error('Server startup crash:', err);
});
