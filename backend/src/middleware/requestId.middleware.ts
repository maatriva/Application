import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

export interface RequestWithId extends Request {
  requestId?: string;
}

export function requestIdMiddleware(req: RequestWithId, res: Response, next: NextFunction) {
  const incomingId = req.headers['x-request-id'] as string | undefined;
  const requestId = incomingId || `req_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);
  next();
}
