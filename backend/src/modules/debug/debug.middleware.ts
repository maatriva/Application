import { Request, Response, NextFunction } from 'express';
import { env } from '../../config/env';

export function debugGate(req: Request, res: Response, next: NextFunction) {
  if (!env.isDebugEnabled) {
    console.warn(`[DEBUG GATE] Blocked access to debug route: ${req.method} ${req.url}`);
    return res.status(404).json({
      success: false,
      message: 'Not Found',
    });
  }
  next();
}
