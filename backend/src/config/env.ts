import dotenv from 'dotenv';

// Load environment variables once from .env in the current working directory
dotenv.config();

export const env = {
  PORT: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
  NODE_ENV: process.env.NODE_ENV || 'development',
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://postgres:Arsh1496@localhost:5432/maatriva?schema=public',
  JWT_SECRET: process.env.JWT_SECRET || 'super_jwt_secret_token_1234',
  JWT_EXPIRATION: '15m',
  JWT_REFRESH_EXPIRATION: '7d',

  // MQTT Settings
  MQTT_HOST: process.env.MQTT_HOST || 'localhost',
  MQTT_PORT: process.env.MQTT_PORT ? parseInt(process.env.MQTT_PORT, 10) : 1883,
  MQTT_CLIENT_ID: process.env.MQTT_CLIENT_ID || 'MaatrivaBackendServer',
  MQTT_USERNAME: process.env.MQTT_USERNAME || undefined,
  MQTT_PASSWORD: process.env.MQTT_PASSWORD || undefined,

  // Gemini API
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || undefined,
};
