import { Request, Response } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { DevicesService } from './devices.service';
import { RegisterDeviceSchema, PairDeviceSchema } from './devices.validation';
import { ZodIssue } from 'zod';

const devicesService = new DevicesService();

export class DevicesController {
  public static async register(req: Request, res: Response) {
    const parseResult = RegisterDeviceSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        error: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const result = await devicesService.registerDevice(parseResult.data);
      res.status(201).json(result);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal registration error' });
    }
  }

  public static async pair(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    const parseResult = PairDeviceSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        error: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const result = await devicesService.pairDevice({
        registrationKey: parseResult.data.registrationKey,
        babyId: parseResult.data.babyId,
        userId,
      });
      res.status(200).json(result);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal pairing error' });
    }
  }

  public static async list(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const devices = await devicesService.listDevices(userId);
      res.json(devices);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch devices error', details: e.message });
    }
  }

  public static async getLatest(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;

    try {
      const latest = await devicesService.getLatestTelemetry(deviceId, userId, userRole);
      res.json(latest);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal fetch latest telemetry error' });
    }
  }

  public static async getHistory(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;
    const sensorType = req.query.type as string;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;

    if (!sensorType) {
      return res.status(400).json({ error: 'sensorType query parameter is required (e.g. ?type=heart_rate).' });
    }

    try {
      const history = await devicesService.getTelemetryHistory(deviceId, sensorType, limit, userId, userRole);
      res.json(history);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal fetch telemetry history error' });
    }
  }

  public static async getAlerts(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;
    const acknowledged = req.query.acknowledged === 'true';

    try {
      const alerts = await devicesService.getDeviceAlerts(deviceId, acknowledged, userId, userRole);
      res.json(alerts);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal fetch alerts error' });
    }
  }

  public static async rename(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;
    const { deviceName } = req.body;

    if (!deviceName) {
      return res.status(400).json({ error: 'deviceName is required.' });
    }

    try {
      const result = await devicesService.renameDevice(deviceId, deviceName, userId, userRole);
      res.json(result);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal rename error' });
    }
  }

  public static async reassign(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;
    const { babyId } = req.body;

    if (!babyId) {
      return res.status(400).json({ error: 'babyId is required.' });
    }

    try {
      const result = await devicesService.reassignBaby(deviceId, babyId, userId, userRole);
      res.json(result);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal reassignment error' });
    }
  }

  public static async unpair(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId || !userRole) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }
    const deviceId = req.params.id;

    try {
      const result = await devicesService.unpairDevice(deviceId, userId, userRole);
      res.json(result);
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ error: e.message || 'Internal unpairing error' });
    }
  }
}
