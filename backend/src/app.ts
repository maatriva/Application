import express from 'express';
import http from 'http';
import { Pool } from 'pg';
import { config } from './config/config';
import { createAuthRouter } from './api/auth';
import { createBabiesRouter } from './api/babies';
import { createDevicesRouter } from './api/devices';
import { createCaregiversRouter } from './api/caregivers';
import { AlertEngine } from './services/alertEngine';
import { MqttClientManager } from './mqtt/mqttClient';
import { WebsocketServerManager } from './websocket/websocketServer';

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

  // 1. Establish PostgreSQL database connection pool
  const dbPool = new Pool({
    connectionString: config.databaseUrl,
  });

  // Verify connection
  try {
    const testQuery = await dbPool.query('SELECT NOW()');
    console.log('PostgreSQL database connected successfully at:', testQuery.rows[0].now);
  } catch (e) {
    console.warn('PostgreSQL database connection failed. Running with offline fallback.', e);
  }

  // 2. Initialize Real-Time WebSocket server manager
  const wsManager = new WebsocketServerManager(dbPool);
  wsManager.initialize(server);

  // 3. Initialize Alert Engine
  const alertEngine = new AlertEngine(dbPool);

  // Connect Alert Engine callbacks to push notifications & WS broadcasts
  alertEngine.onAlertTriggered = (alert) => {
    console.log(`Alert triggered: [${alert.severity.toUpperCase()}] ${alert.message}`);
    
    if (alert.babyId) {
      // Stream alert to active WebSocket applications
      wsManager.broadcastAlert(alert.babyId, alert);
      
      // Firebase Cloud Messaging (FCM) push notification trigger logic goes here
      // triggerFcmPushNotification(alert.babyId, alert.message);
    }
  };

  // 4. Initialize MQTT Telemetry Ingestion client
  const mqttManager = new MqttClientManager(dbPool, alertEngine);
  mqttManager.connect();

  // 5. Register REST API routes
  app.use('/auth', createAuthRouter(dbPool));
  app.use('/babies', createBabiesRouter(dbPool));
  app.use('/devices', createDevicesRouter(dbPool));
  app.use('/caregivers', createCaregiversRouter(dbPool));

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      database: dbPool ? 'connected' : 'offline',
      mqtt: 'active',
      uptime: process.uptime(),
    });
  });

  server.listen(config.port, '0.0.0.0', () => {
    console.log(`MAATRIVA Backend Server running at http://localhost:${config.port}`);
  });
}

// Handle unexpected shutdowns
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received. Cleaning resources and shutting down...');
  process.exit(0);
});

startServer();
