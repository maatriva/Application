import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { UserRole } from '@prisma/client';
import { prisma } from '../config/database';

export interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    role: UserRole;
  };
}

export function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required.' });
  }

  jwt.verify(token, env.JWT_SECRET, async (err, decoded: any) => {
    if (err) {
      return res.status(401).json({ error: 'Invalid or expired token.' });
    }
    const authReq = req as AuthenticatedRequest;
    authReq.user = {
      userId: decoded.userId,
      role: decoded.role as UserRole,
    };

    // Restricted Caregiver Enforcements
    if (authReq.user.role === 'CAREGIVER') {
      try {
        const isRestricted = await prisma.caregiver.findFirst({
          where: {
            userId: authReq.user.userId,
            status: 'accepted',
            accessLevel: 'LIVE_MONITOR_ONLY',
          },
        });

        if (isRestricted) {
          const method = req.method;
          const fullPath = (req.baseUrl + req.path).replace(/\/$/, '');

          const isAllowed =
            (method === 'GET' && /^\/devices\/[^\/]+\/latest$/.test(fullPath)) ||
            (method === 'GET' && /^\/telemetry\/latest\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && /^\/telemetry\/history\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && /^\/devices\/[^\/]+\/alerts$/.test(fullPath)) ||
            (method === 'POST' && (fullPath === '/caregivers/accept' || fullPath === '/caregivers/invitation/accept' || fullPath === '/caregivers/invitation/reject')) ||
            (method === 'GET' && (fullPath === '/caregivers/invitations' || fullPath === '/caregivers')) ||
            (method === 'GET' && fullPath === '/babies') ||
            (method === 'GET' && /^\/babies\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && (fullPath === '/users/profile' || fullPath === '/auth/profile'));

          if (!isAllowed) {
            console.warn(`[RESTRICTION] Blocked caregiver request to ${method} ${fullPath}`);
            return res.status(403).json({
              error: 'Forbidden: Restricted live monitoring access only.',
            });
          }
        }
      } catch (dbErr) {
        console.error('[authMiddleware] DB check failed:', dbErr);
        return res.status(500).json({ error: 'Internal security check error.' });
      }
    }

    next();
  });
}

export function requireRole(allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.user) {
      return res.status(401).json({ error: 'Unauthorized: Authentication required.' });
    }
    if (!allowedRoles.includes(authReq.user.role)) {
      return res.status(403).json({ error: 'Forbidden: Insufficient privileges.' });
    }
    next();
  };
}
