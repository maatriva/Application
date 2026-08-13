import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';
import { sanitizeString } from '../utils/sanitizer.utils';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) {
  const status = err.status || err.statusCode || 500;
  const rawMessage = err.message || 'Internal Server Error';
  const cleanMessage = sanitizeString(rawMessage);

  console.error(`[ERROR] ${req.method} ${req.url} status=${status}: ${cleanMessage}`);

  res.status(status).json({
    error: cleanMessage,
    ...(env.NODE_ENV === 'development' && { details: err.stack ? sanitizeString(err.stack) : cleanMessage }),
  });
}
