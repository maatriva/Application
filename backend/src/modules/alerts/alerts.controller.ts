import { Response } from 'express';
import { prisma } from '../../config/database';
import { AuthenticatedRequest } from '../auth/auth.types';

export class AlertsController {
  /**
   * Helper to fetch baby IDs associated with the current caregiver/parent with strict authorization checks.
   */
  private static async getAuthorizedBabyIds(userId: string): Promise<string[]> {
    const now = new Date();
    const authorizedIds = new Set<string>();

    // 1. Fetch babies owned by parent
    const parentBabies = await prisma.baby.findMany({
      where: { parentId: userId, deletedAt: null },
      select: { id: true },
    });
    for (const b of parentBabies) {
      authorizedIds.add(b.id);
    }

    // 2. Fetch active temporary permissions
    const activeTempPerms = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: {
        caregiverId: userId,
        status: 'ACTIVE',
        revoked: false,
        expiresAt: { gt: now },
      },
      select: { babyId: true },
    });
    for (const tp of activeTempPerms) {
      if (tp.babyId) authorizedIds.add(tp.babyId);
    }

    // 3. Fetch base caregiver records ONLY IF no temporary permission record exists for that baby
    const baseCaregivers = await prisma.caregiver.findMany({
      where: {
        userId,
        status: 'accepted',
      },
      select: { babyId: true },
    });
    for (const cg of baseCaregivers) {
      if (cg.babyId) {
        const hasTempRecord = await (prisma as any).temporaryCaregiverPermission.findFirst({
          where: {
            caregiverId: userId,
            babyId: cg.babyId,
          },
        });
        if (!hasTempRecord) {
          authorizedIds.add(cg.babyId);
        }
      }
    }

    return Array.from(authorizedIds);
  }

  /**
   * GET /alerts
   * Paginated alerts fetch for authorized babies
   */
  public static async getAlerts(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = Math.min(100, parseInt(req.query.limit as string, 10) || 50);
    const skip = (page - 1) * limit;

    try {
      const babyIds = await AlertsController.getAuthorizedBabyIds(userId);
      const alerts = await prisma.alert.findMany({
        where: {
          babyId: { in: babyIds },
        },
        orderBy: { timestamp: 'desc' },
        skip,
        take: limit,
      });

      const mappedAlerts = alerts.map((a) => ({
        ...a,
        severity: a.severity === 'danger' && a.type === 'CRY_DETECTED' ? 'HIGH' : a.severity,
      }));

      res.json({
        success: true,
        message: 'Alerts retrieved successfully.',
        data: mappedAlerts,
        pagination: {
          page,
          limit,
          count: mappedAlerts.length,
        },
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Internal server error while fetching alerts.',
      });
    }
  }

  /**
   * PATCH /alerts/:id/read
   * Support marking a specific alert as read (or all if id is 'all')
   */
  public static async markAsRead(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const { id } = req.params;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    try {
      const babyIds = await AlertsController.getAuthorizedBabyIds(userId);

      if (id === 'all') {
        await prisma.alert.updateMany({
          where: {
            babyId: { in: babyIds },
            acknowledged: false,
          },
          data: {
            acknowledged: true,
            acknowledgedBy: userId,
            acknowledgedAt: new Date(),
          },
        });

        return res.json({
          success: true,
          message: 'All alerts marked as read successfully.',
          data: {},
        });
      }

      // Read a specific alert
      const alert = await prisma.alert.findUnique({
        where: { id },
      });

      if (!alert) {
        return res.status(404).json({ success: false, message: 'Alert not found.' });
      }

      if (alert.babyId && !babyIds.includes(alert.babyId)) {
        return res.status(403).json({ success: false, message: 'Access denied to this alert.' });
      }

      const updated = await prisma.alert.update({
        where: { id },
        data: {
          acknowledged: true,
          acknowledgedBy: userId,
          acknowledgedAt: new Date(),
        },
      });

      res.json({
        success: true,
        message: 'Alert marked as read successfully.',
        data: updated,
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Internal server error marking alert as read.',
      });
    }
  }

  /**
   * DELETE /alerts/:id
   */
  public static async deleteAlert(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const { id } = req.params;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    try {
      const babyIds = await AlertsController.getAuthorizedBabyIds(userId);
      const alert = await prisma.alert.findUnique({
        where: { id },
      });

      if (!alert) {
        return res.status(404).json({ success: false, message: 'Alert not found.' });
      }

      if (alert.babyId && !babyIds.includes(alert.babyId)) {
        return res.status(403).json({ success: false, message: 'Access denied to this alert.' });
      }

      await prisma.alert.delete({
        where: { id },
      });

      res.json({
        success: true,
        message: 'Alert deleted successfully.',
        data: {},
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Internal server error deleting alert.',
      });
    }
  }

  /**
   * DELETE /alerts (Clear all)
   */
  public static async clearAll(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    try {
      const babyIds = await AlertsController.getAuthorizedBabyIds(userId);

      await prisma.alert.deleteMany({
        where: {
          babyId: { in: babyIds },
        },
      });

      res.json({
        success: true,
        message: 'All alerts cleared successfully.',
        data: {},
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Internal server error clearing alerts.',
      });
    }
  }
}
