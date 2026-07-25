import { Request, Response, NextFunction } from 'express';
import { env } from '../../config/env';

export function debugGate(req: Request, res: Response, next: NextFunction) {
  const isDev = env.NODE_ENV === 'development';
  const isDebugMode = process.env.DEBUG_MODE === 'true';

  if (!isDev && !isDebugMode) {
    console.warn(`[DEBUG GATE] Blocked production access to debug route: ${req.method} ${req.url}`);
    return res.status(404).json({
      success: false,
      message: 'Not Found',
    });
  }
  next();
}
