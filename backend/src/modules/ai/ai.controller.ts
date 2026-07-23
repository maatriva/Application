import { Request, Response } from 'express';
import { AiService } from './ai.service';

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
}
