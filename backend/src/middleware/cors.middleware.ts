import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

/**
 * Hardened CORS Middleware.
 * Enforces exact origin matching against an explicit allowlist.
 * Prevents dynamic reflection of unapproved incoming Origin headers.
 */
export function corsMiddleware(req: Request, res: Response, next: NextFunction) {
  const originHeader = req.headers.origin;

  // Requests without an Origin header (e.g. mobile clients, server-to-server, health checks)
  if (!originHeader) {
    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    return next();
  }

  const requestOrigin = originHeader.trim();
  const allowedOrigins = env.allowedOrigins;

  // Exact origin matching (case-insensitive) against configured allowlist
  const isAllowed = allowedOrigins.some(
    (allowed) => allowed.toLowerCase() === requestOrigin.toLowerCase()
  );

  if (isAllowed) {
    res.setHeader('Access-Control-Allow-Origin', requestOrigin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept, Authorization'
    );
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Private-Network', 'true');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');

    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    return next();
  }

  // Preflight requests for unapproved origins are rejected with 403 Forbidden
  if (req.method === 'OPTIONS') {
    return res.status(403).json({
      success: false,
      message: 'CORS policy: Origin not allowed.',
    });
  }

  // For non-preflight requests from unapproved origins:
  // Do NOT set Access-Control-Allow-Origin or Access-Control-Allow-Credentials.
  return next();
}
