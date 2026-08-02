import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { UserRole } from '@prisma/client';
import { AuthenticatedRequest, TokenPayload } from './auth.types';

/**
 * Authenticates requests checking the JWT Access Token in the Authorization header.
 */
export function authenticateToken(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token required.',
    });
  }

  jwt.verify(token, env.JWT_SECRET, (err, decoded: any) => {
    if (err) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token.',
      });
    }

    req.user = {
      userId: decoded.userId,
      role: decoded.role as UserRole,
    };
    next();
  });
}

/**
 * Authorization middleware to check if the authenticated user has a permitted role.
 */
export function requireRole(allowedRoles: UserRole[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: Insufficient privileges.',
      });
    }
    next();
  };
}
