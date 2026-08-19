import rateLimit from 'express-rate-limit';
import { env } from '../config/env';

/**
 * General API Rate Limiter
 * Prevents HTTP flood attacks across normal application routes while skipping health probes.
 */
export const generalApiLimiter = rateLimit({
  windowMs: env.API_RATE_LIMIT_WINDOW_MS,
  max: env.API_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.path === '/health' || req.path === '/api/health' || req.originalUrl === '/health',
  message: {
    success: false,
    message: 'Too many requests. Please try again later.',
  },
  statusCode: 429,
});

/**
 * Strict Authentication Rate Limiter
 * Applied to /auth/login, /auth/register, /auth/refresh to prevent credential stuffing and brute-force attacks.
 */
export const authLimiter = rateLimit({
  windowMs: env.AUTH_RATE_LIMIT_WINDOW_MS,
  max: env.AUTH_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication attempts. Please try again later.',
  },
  statusCode: 429,
});
