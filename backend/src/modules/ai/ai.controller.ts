import { Request, Response } from 'express';
import { AiService } from './ai.service';
import { prisma } from '../../config/database';

const aiService = new AiService();

export class AiController {
  public static async getInsight(req: Request, res: Response) {
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
      console.error('Gemini Insight Generation Error:', error);
      res.status(500).json({
        error: 'Could not generate AI insights.',
        details: error.message || error,
      });
    }
  }

  public static async getReport(req: Request, res: Response) {
    try {
      const { babyId } = req.params;
      const type = (req.query.type as string) || 'daily';

      if (type !== 'daily' && type !== 'weekly' && type !== 'monthly') {
        return res.status(400).json({
          error: 'Invalid report type. Supported types: daily, weekly, monthly.',
        });
      }

      const userId = (req as any).user?.userId;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized.' });
      }

      // Verify parent ownership of the baby
      const baby = await prisma.baby.findFirst({
        where: {
          id: babyId,
          parentId: userId,
          deletedAt: null,
        },
      });

      if (!baby) {
        return res.status(403).json({
          error: 'Access denied or baby profile not found.',
        });
      }

      const report = await aiService.getReport(babyId, type as 'daily' | 'weekly' | 'monthly');
      res.json(report);
    } catch (error: any) {
      console.error('AI Report Generation Error:', error);
      res.status(500).json({
        error: 'Could not generate AI report.',
        details: error.message || error,
      });
    }
  }
}
