import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

/**
 * Hardened CORS Middleware.
 * Enforces exact origin matching against an explicit allowlist.
 * Prevents dynamic reflection of unapproved incoming Origin headers.
 */
export function corsMiddleware(req: Request, res: Response, next: NextFunction) {
  const originHeader = req.headers.origin;

  // Requests without an Origin header (e.g. mobile Flutter native apps, server-to-server, health checks)
  if (!originHeader) {
    if (req.method === 'OPTIONS') {
      return res.status(204).end();
    }
    return next();
  }

  const requestOrigin = originHeader.trim().replace(/\/$/, '');

  // Reject 'null' origin explicitly
  if (requestOrigin === 'null') {
    if (req.method === 'OPTIONS') {
      return res.status(403).json({ success: false, message: 'CORS policy: Null origin not allowed.' });
    }
    return next();
  }

  const allowedOrigins = env.allowedOrigins.map((o) => o.replace(/\/$/, ''));

  // In development mode, automatically permit any local development origin (localhost / 127.0.0.1 on any port)
  const isLocalDevOrigin =
    !env.isProduction &&
    /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(requestOrigin);

  // Exact origin matching (case-insensitive) against configured allowlist or local dev origins
  const isAllowed =
    isLocalDevOrigin ||
    allowedOrigins.some(
      (allowed) => allowed.toLowerCase() === requestOrigin.toLowerCase()
    );

  if (isAllowed) {
    res.setHeader('Access-Control-Allow-Origin', originHeader.trim());
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Request-ID'
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
