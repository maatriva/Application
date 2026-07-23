import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { TelemetryService } from './telemetry.service';
import { HistoryQuerySchema } from './telemetry.validation';
import { ZodIssue } from 'zod';

const telemetryService = new TelemetryService();

export class TelemetryController {
  /**
   * GET /telemetry/latest/:babyId
   * Return latest reading. Only owner parent can access.
   */
  public static async getLatest(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    const babyId = req.params.babyId;

    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    try {
      const data = await telemetryService.getLatestReading(babyId, parentId);
      return res.status(200).json({
        success: true,
        message: 'Latest telemetry reading fetched successfully.',
        data: data || {},
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal fetch latest telemetry error.',
      });
    }
  }

  /**
   * GET /telemetry/history/:babyId
   * Return telemetry history. Supports from, to, and limit. Only owner parent can access.
   */
  public static async getHistory(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    const babyId = req.params.babyId;

    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    const parseResult = HistoryQuerySchema.safeParse(req.query);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    const filters = {
      from: parseResult.data.from ? new Date(parseResult.data.from) : undefined,
      to: parseResult.data.to ? new Date(parseResult.data.to) : undefined,
      limit: parseResult.data.limit,
    };

    try {
      const data = await telemetryService.getHistory(babyId, parentId, filters);
      return res.status(200).json({
        success: true,
        message: 'Telemetry history fetched successfully.',
        data,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal fetch telemetry history error.',
      });
    }
  }
}
