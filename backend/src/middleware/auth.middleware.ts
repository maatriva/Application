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
        const now = new Date();
        const fullPath = (req.baseUrl + req.path).replace(/\/$/, '');
        const method = req.method;

        // Paths needed for authentication, profile, and checking permission status
        const isSelfManagementPath =
          fullPath === '/users/profile' ||
          fullPath === '/auth/profile' ||
          fullPath === '/caregivers/active-permissions' ||
          fullPath === '/caregiver/active-permissions' ||
          fullPath === '/caregivers/access' ||
          fullPath === '/caregiver/access' ||
          fullPath === '/caregiver/access/active' ||
          fullPath === '/caregivers/access/active' ||
          fullPath === '/caregivers/invitations' ||
          fullPath === '/caregivers/accept' ||
          fullPath === '/caregivers/invitation/accept' ||
          fullPath === '/caregivers/invitation/reject';

        if (!isSelfManagementPath) {
          // Verify caregiver has an active, unexpired, non-revoked permission record in DB
          const activeTempPerm = await (prisma as any).temporaryCaregiverPermission.findFirst({
            where: {
              caregiverId: authReq.user.userId,
              revoked: false,
              expiresAt: { gt: now },
            },
          });

          const activeCaregiver = await prisma.caregiver.findFirst({
            where: {
              userId: authReq.user.userId,
              status: 'accepted',
            },
          });

          if (!activeTempPerm && !activeCaregiver) {
            console.warn(`[RESTRICTION] Blocked caregiver ${authReq.user.userId}: Permission expired or revoked.`);
            return res.status(403).json({
              error: 'Your caregiver monitoring access has expired or been revoked by the parent.',
              code: 'ACCESS_EXPIRED_OR_REVOKED',
            });
          }
        }

        const isRestricted = await prisma.caregiver.findFirst({
          where: {
            userId: authReq.user.userId,
            status: 'accepted',
            accessLevel: 'LIVE_MONITOR_ONLY',
          },
        });

        if (isRestricted) {
          const isAllowed =
            (method === 'GET' && /^\/devices\/[^\/]+\/latest$/.test(fullPath)) ||
            (method === 'GET' && /^\/telemetry\/latest\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && /^\/telemetry\/history\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && /^\/devices\/[^\/]+\/alerts$/.test(fullPath)) ||
            (method === 'POST' && (fullPath === '/caregivers/accept' || fullPath === '/caregivers/invitation/accept' || fullPath === '/caregivers/invitation/reject')) ||
            (method === 'GET' && (fullPath === '/caregivers/invitations' || fullPath === '/caregivers' || fullPath === '/caregivers/active-permissions' || fullPath === '/caregivers/access' || fullPath === '/caregiver/access')) ||
            (method === 'GET' && (fullPath === '/music' || fullPath === '/music/shared')) ||
            (method === 'GET' && fullPath === '/babies') ||
            (method === 'GET' && /^\/babies\/[^\/]+$/.test(fullPath)) ||
            (method === 'GET' && (fullPath === '/users/profile' || fullPath === '/auth/profile'));

          if (!isAllowed) {
            console.warn(`[RESTRICTION] Blocked caregiver request to ${method} ${fullPath}`);
            return res.status(403).json({
              error: 'Forbidden: Restricted live monitoring access only.',
              code: 'RESTRICTED_ACCESS_ONLY',
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

export function optionalAuthenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return next();
  }

  jwt.verify(token, env.JWT_SECRET, (err, decoded: any) => {
    if (!err && decoded) {
      const authReq = req as AuthenticatedRequest;
      authReq.user = {
        userId: decoded.userId,
        role: decoded.role as UserRole,
      };
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

