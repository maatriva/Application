import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, '../../../.env') });

export const config = {
  port: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgres://maatriva_admin:admin_secret_pass@localhost:5432/maatriva',
  
  // MQTT settings
  mqttHost: process.env.MQTT_HOST || 'localhost',
  mqttPort: process.env.MQTT_PORT ? parseInt(process.env.MQTT_PORT, 10) : 1883,
  mqttClientId: process.env.MQTT_CLIENT_ID || 'MaatrivaBackendServer',
  mqttUsername: process.env.MQTT_USERNAME || undefined,
  mqttPassword: process.env.MQTT_PASSWORD || undefined,

  // JWT Secret for authentication
  jwtSecret: process.env.JWT_SECRET || 'super_jwt_secret_token_1234',
  jwtExpiration: '15m',
  jwtRefreshExpiration: '7d',

  // FCM Settings
  fcmProjectId: process.env.FCM_PROJECT_ID || 'maatriva-smart-cradle',
  fcmServiceAccountCert: process.env.FCM_SERVICE_ACCOUNT_JSON || undefined,
};
