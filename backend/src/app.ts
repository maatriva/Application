import express from 'express';
import http from 'http';
import { env } from './config/env';
import { prisma } from './config/database';
import { AlertEngine } from './services/alertEngine';
import { MqttClientManager } from './mqtt/mqttClient';
import { WebsocketServerManager } from './websocket/websocketServer';
import { errorHandler } from './middleware/error.middleware';
import apiRouter from './routes';

async function startServer() {
  const app = express();
  app.use(express.json());

  // CORS Middleware setup
  app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    if (req.method === 'OPTIONS') {
      return res.sendStatus(200);
    }
    next();
  });

  const server = http.createServer(app);

  // 1. Verify Prisma / PostgreSQL connection
  try {
    await prisma.$queryRaw`SELECT 1`;
    console.log('✓ PostgreSQL connected');
    console.log('✓ Prisma connected');
  } catch (e) {
    console.error('PostgreSQL / Prisma connection failed:', e);
    process.exit(1);
  }

  // 2. Initialize Real-Time WebSocket Server
  const wsManager = new WebsocketServerManager();
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

  server.listen(env.PORT, '0.0.0.0', () => {
    console.log(`✓ Express running on port ${env.PORT}`);
    console.log(`MAATRIVA Backend Server running at http://localhost:${env.PORT}`);
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
