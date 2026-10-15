import dotenv from 'dotenv';

// Load environment variables once from .env in the current working directory
dotenv.config();

function getRequiredEnvVar(key: string): string {
  const val = process.env[key];
  if (!val || val.trim() === '') {
    throw new Error(`[FATAL] Required environment variable "${key}" is missing or empty. Ensure it is defined in your environment or .env file.`);
  }
  return val.trim();
}

const nodeEnv = (process.env.NODE_ENV || 'development').toLowerCase().trim();
const isProduction = nodeEnv === 'production';
const isDebugMode = process.env.DEBUG_MODE === 'true';

// Debug routes are allowed in development mode or when DEBUG_MODE is explicitly set to 'true'.
const isDebugEnabled = !isProduction || isDebugMode;

function parseCorsOrigins(isProd: boolean): string[] {
  const raw = process.env.CORS_ORIGINS;
  if (raw && raw.trim() !== '') {
    return raw
      .split(',')
      .map((o) => o.trim())
      .filter(Boolean);
  }
  if (isProd) {
    return [];
  }
  return [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5173',
    'https://staging-api.maatriva.cloud',
    'https://api.maatriva.co.in',
  ];
}

export const env = {
  PORT: process.env.PORT ? parseInt(process.env.PORT, 10) : 3000,
  HOST: process.env.HOST || '0.0.0.0',
  NODE_ENV: nodeEnv,
  DEBUG_MODE: isDebugMode,
  isProduction,
  isDevelopment: nodeEnv === 'development',
  isTest: nodeEnv === 'test',
  isDebugEnabled,
  allowedOrigins: parseCorsOrigins(isProduction),
  DATABASE_URL: getRequiredEnvVar('DATABASE_URL'),
  JWT_SECRET: getRequiredEnvVar('JWT_SECRET'),
  JWT_EXPIRATION: '15m',
  JWT_REFRESH_EXPIRATION: '7d',

  // MQTT Settings
  ENABLE_MQTT: process.env.ENABLE_MQTT === 'true',
  MQTT_HOST: process.env.MQTT_HOST || '',
  MQTT_PORT: process.env.MQTT_PORT ? parseInt(process.env.MQTT_PORT, 10) : 1883,
  MQTT_CLIENT_ID: process.env.MQTT_CLIENT_ID || 'MaatrivaBackendServer',
  MQTT_USERNAME: process.env.MQTT_USERNAME || undefined,
  MQTT_PASSWORD: process.env.MQTT_PASSWORD || undefined,

  // Gemini API
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || undefined,

  // Rate Limiting & Security Limits
  JSON_BODY_LIMIT: process.env.JSON_BODY_LIMIT || '2mb',
  URLENCODED_BODY_LIMIT: process.env.URLENCODED_BODY_LIMIT || '2mb',
  API_RATE_LIMIT_WINDOW_MS: process.env.API_RATE_LIMIT_WINDOW_MS ? parseInt(process.env.API_RATE_LIMIT_WINDOW_MS, 10) : 15 * 60 * 1000,
  API_RATE_LIMIT_MAX: process.env.API_RATE_LIMIT_MAX ? parseInt(process.env.API_RATE_LIMIT_MAX, 10) : 300,
  AUTH_RATE_LIMIT_WINDOW_MS: process.env.AUTH_RATE_LIMIT_WINDOW_MS ? parseInt(process.env.AUTH_RATE_LIMIT_WINDOW_MS, 10) : 15 * 60 * 1000,
  AUTH_RATE_LIMIT_MAX: process.env.AUTH_RATE_LIMIT_MAX ? parseInt(process.env.AUTH_RATE_LIMIT_MAX, 10) : 15,
  TRUST_PROXY: process.env.TRUST_PROXY === 'true' || isProduction,

  // File Upload Size Limits (in Megabytes)
  MAX_AUDIO_UPLOAD_MB: process.env.MAX_AUDIO_UPLOAD_MB ? parseInt(process.env.MAX_AUDIO_UPLOAD_MB, 10) : 10,
  MAX_MUSIC_UPLOAD_MB: process.env.MAX_MUSIC_UPLOAD_MB ? parseInt(process.env.MAX_MUSIC_UPLOAD_MB, 10) : 15,
  MAX_IMAGE_UPLOAD_MB: process.env.MAX_IMAGE_UPLOAD_MB ? parseInt(process.env.MAX_IMAGE_UPLOAD_MB, 10) : 5,
};
