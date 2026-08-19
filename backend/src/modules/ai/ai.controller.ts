import { Response } from 'express';
import { AiService } from './ai.service';
import { prisma } from '../../config/database';
import { AuthenticatedRequest } from '../auth/auth.types';
import { Logger } from '../../utils/logger';

const aiService = new AiService();

export class AiController {
  public static async getInsight(req: AuthenticatedRequest, res: Response) {
    try {
      const { babyStatus, temperature, heartRate, sleepHours, cryCount } = req.body;
      const insight = await aiService.generateDailyInsight({
        babyStatus,
        temperature,
        heartRate,
        sleepHours,
        cryCount,
      });
      res.json({ insight });
    } catch (error: any) {
      Logger.error('Gemini Insight Generation Error:', { error });
      res.status(500).json({
        error: 'Could not generate AI insights.',
      });
    }
  }

  public static async getReport(req: AuthenticatedRequest, res: Response) {
    try {
      const { babyId } = req.params;
      const type = (req.query.type as string) || 'daily';

      if (type !== 'daily' && type !== 'weekly' && type !== 'monthly') {
        return res.status(400).json({
          error: 'Invalid report type. Supported types: daily, weekly, monthly.',
        });
      }

      const userId = req.user?.userId;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized.' });
      }

      const now = new Date();
      // Verify parent ownership or active caregiver permission
      const authorizedBaby = await prisma.baby.findFirst({
        where: {
          id: babyId,
          deletedAt: null,
          OR: [
            { parentId: userId },
            {
              temporaryCaregiverPermissions: {
                some: {
                  caregiverId: userId,
                  status: 'ACTIVE',
                  revoked: false,
                  expiresAt: { gt: now },
                },
              },
            },
            {
              caregivers: {
                some: {
                  userId,
                  status: 'accepted',
                },
              },
            },
          ],
        },
      });

      if (!authorizedBaby) {
        return res.status(403).json({
          error: 'Access denied or baby profile not found.',
        });
      }

      const report = await aiService.getReport(babyId, type as 'daily' | 'weekly' | 'monthly');
      res.json(report);
    } catch (error: any) {
      Logger.error('AI Report Generation Error:', { error });
      res.status(500).json({
        error: 'Could not generate AI report.',
      });
    }
  }
}
