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
  let token = authHeader && authHeader.split(' ')[1];

  if (!token && req.query.token && typeof req.query.token === 'string') {
    token = req.query.token;
  }

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
        const normPath = fullPath.replace(/^\/api/, '');
        const method = req.method;

        // Paths needed for authentication, profile, and checking permission status
        const isSelfManagementPath =
          normPath === '/users/profile' ||
          normPath === '/auth/profile' ||
          normPath === '/caregivers/active-permissions' ||
          normPath === '/caregiver/active-permissions' ||
          normPath === '/caregivers/access' ||
          normPath === '/caregiver/access' ||
          normPath === '/caregiver/access/active' ||
          normPath === '/caregivers/access/active' ||
          normPath === '/caregivers/invitations' ||
          normPath === '/caregivers/accept' ||
          normPath === '/caregivers/invitation/accept' ||
          normPath === '/caregivers/access/accept' ||
          normPath === '/caregivers/invitation/reject' ||
          normPath === '/caregivers/server-time';

        if (!isSelfManagementPath) {
          // Extract babyId from query, body, path params, or URL path segments
          const pathSegments = normPath.split('/');
          let targetBabyId = (req.params.babyId || req.query.babyId || req.body.babyId) as string | undefined;
          if (!targetBabyId && pathSegments[1] === 'babies' && pathSegments[2] && pathSegments[2] !== 'undefined') {
            targetBabyId = pathSegments[2];
          }

          const whereClause: any = {
            caregiverId: authReq.user.userId,
            revoked: false,
            expiresAt: { gt: now },
            status: 'ACTIVE',
          };
          if (targetBabyId) {
            whereClause.babyId = targetBabyId;
          }

          const activeTempPerm = await (prisma as any).temporaryCaregiverPermission.findFirst({
            where: whereClause,
          });

          // Check if caregiver has any temporary QR permission record for this baby
          const hasTempRecord = await (prisma as any).temporaryCaregiverPermission.findFirst({
            where: {
              caregiverId: authReq.user.userId,
              ...(targetBabyId && { babyId: targetBabyId }),
            },
          });

          let isAuthorized = false;
          if (activeTempPerm) {
            isAuthorized = true;
          } else if (!hasTempRecord) {
            // Permanent base caregiver mapping (e.g. SECONDARY_PARENT, CO_PARENT)
            const activeCaregiver = await prisma.caregiver.findFirst({
              where: {
                userId: authReq.user.userId,
                status: 'accepted',
                accessLevel: { in: ['SECONDARY_PARENT', 'CO_PARENT', 'PERMANENT_CAREGIVER'] },
                ...(targetBabyId && { babyId: targetBabyId }),
              },
            });
            if (activeCaregiver) {
              isAuthorized = true;
            }
          }

          if (!isAuthorized) {
            console.warn(`[RESTRICTION] Blocked caregiver ${authReq.user.userId}: Permission expired or revoked.`);
            return res.status(403).json({
              error: 'Your caregiver monitoring access has expired or been revoked by the parent.',
              code: 'ACCESS_EXPIRED_OR_REVOKED',
            });
          }

          // Enforce specific action permission flags if temporary caregiver permission exists
          if (activeTempPerm) {
            if (normPath.startsWith('/cradle') && !activeTempPerm.canControlCradle) {
              return res.status(403).json({ error: 'Access denied: Cradle control permission disabled by parent.', code: 'PERMISSION_DISABLED' });
            }
            if (normPath.startsWith('/music/recordings') && !activeTempPerm.canViewCustomLullabies && !activeTempPerm.canPlayMusic) {
              return res.status(403).json({ error: 'Access denied: Custom parent folder permission disabled by parent.', code: 'PERMISSION_DISABLED' });
            }
            if (normPath.startsWith('/ai') && !activeTempPerm.canUseAI) {
              return res.status(403).json({ error: 'Access denied: AI chatbot permission disabled by parent.', code: 'PERMISSION_DISABLED' });
            }
            if (normPath.startsWith('/telemetry/history') && !activeTempPerm.canViewTelemetry) {
              return res.status(403).json({ error: 'Access denied: Historical telemetry reports disabled by parent.', code: 'PERMISSION_DISABLED' });
            }
            if (normPath.startsWith('/camera') && !activeTempPerm.canViewCamera) {
              return res.status(403).json({ error: 'Access denied: Live video permission disabled by parent.', code: 'PERMISSION_DISABLED' });
            }
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
            (method === 'GET' && /^\/devices\/[^\/]+\/latest$/.test(normPath)) ||
            (method === 'GET' && /^\/telemetry\/latest\/[^\/]+$/.test(normPath)) ||
            (method === 'GET' && /^\/telemetry\/history\/[^\/]+$/.test(normPath)) ||
            (method === 'GET' && /^\/devices\/[^\/]+\/alerts$/.test(normPath)) ||
            (method === 'POST' && (normPath === '/caregivers/accept' || normPath === '/caregivers/invitation/accept' || normPath === '/caregivers/access/accept' || normPath === '/caregivers/invitation/reject')) ||
            (method === 'GET' && (normPath === '/caregivers/invitations' || normPath === '/caregivers' || normPath === '/caregivers/active-permissions' || normPath === '/caregivers/access' || normPath === '/caregiver/access' || normPath === '/caregivers/server-time')) ||
            (method === 'GET' && (normPath === '/music' || normPath === '/music/shared')) ||
            (method === 'GET' && normPath === '/babies') ||
            (method === 'GET' && /^\/babies\/[^\/]+$/.test(normPath)) ||
            (method === 'GET' && (normPath === '/users/profile' || normPath === '/auth/profile'));

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
  let token = authHeader && authHeader.split(' ')[1];

  if (!token && req.query.token && typeof req.query.token === 'string') {
    token = req.query.token;
  }

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
