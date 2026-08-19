import { Response, NextFunction } from 'express';
import { env } from '../config/env';
import { sanitizeString } from '../utils/sanitizer.utils';
import { Logger } from '../utils/logger';
import { RequestWithId } from './requestId.middleware';

export function errorHandler(
  err: any,
  req: RequestWithId,
  res: Response,
  next: NextFunction
) {
  const requestId = req.requestId;

  if (err.name === 'MulterError' || err.code === 'LIMIT_FILE_SIZE') {
    const isSizeError = err.code === 'LIMIT_FILE_SIZE';
    const status = isSizeError ? 413 : 400;
    const cleanMessage = isSizeError
      ? 'Payload Too Large: File size exceeds the allowed upload limit.'
      : sanitizeString(err.message || 'File upload validation error.');

    Logger.error(`[UPLOAD ERROR] ${req.method} ${req.url} status=${status}: ${cleanMessage}`, {
      requestId,
      status,
      code: err.code || 'UPLOAD_ERROR',
    });

    return res.status(status).json({
      error: cleanMessage,
      code: err.code || 'UPLOAD_ERROR',
    });
  }

  if (err.message && err.message.includes('Invalid audio file type')) {
    Logger.error(`[UPLOAD ERROR] ${req.method} ${req.url} status=400: ${err.message}`, {
      requestId,
      status: 400,
      code: 'INVALID_FILE_TYPE',
    });
    return res.status(400).json({
      error: sanitizeString(err.message),
      code: 'INVALID_FILE_TYPE',
    });
  }

  const status = err.status || err.statusCode || 500;
  const rawMessage = err.message || 'Internal Server Error';
  const cleanMessage = sanitizeString(rawMessage);

  Logger.error(`[ERROR] ${req.method} ${req.url} status=${status}: ${cleanMessage}`, {
    requestId,
    status,
  });

  // Safe Production Response: Never leak stack traces, SQL queries, or secrets in production
  if (env.NODE_ENV === 'production' && status === 500) {
    return res.status(500).json({
      error: 'Internal Server Error',
      code: 'INTERNAL_SERVER_ERROR',
    });
  }

  res.status(status).json({
    error: cleanMessage,
    ...(env.NODE_ENV === 'development' && { details: err.stack ? sanitizeString(err.stack) : cleanMessage }),
  });
}
