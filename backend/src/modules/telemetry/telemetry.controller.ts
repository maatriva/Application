import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { TelemetryService } from './telemetry.service';
import { HistoryQuerySchema, IngestTelemetrySchema } from './telemetry.validation';
import { ZodIssue } from 'zod';
import { prisma } from '../../config/database';
import { WebsocketServerManager } from '../../websocket/websocketServer';
import { AlertEngine } from '../../services/alertEngine';

const telemetryService = new TelemetryService();

export class TelemetryController {
  /**
   * POST /telemetry
   * Ingest telemetry from device or simulator.
   */
  public static async ingest(req: Request, res: Response, next: NextFunction) {
    const parseResult = IngestTelemetrySchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    const data = parseResult.data;
    const deviceId = data.deviceId;

    try {
      // 1. Verify device exists
      const device = await prisma.device.findUnique({
        where: { deviceId },
      });

      if (!device) {
        return res.status(404).json({
          success: false,
          message: `Unknown device: Device ${deviceId} not found.`,
        });
      }

      // 2. Verify device is paired (has active assignment)
      const assignment = await prisma.deviceAssignment.findFirst({
        where: { deviceId },
      });

      if (!device.paired || !assignment) {
        return res.status(400).json({
          success: false,
          message: `Unpaired device: Device ${deviceId} is not paired with any baby.`,
        });
      }

      const babyId = assignment.babyId;

      // 3. Map fields to fit the db schema
      const mappedRespirationRate = data.respirationRate ?? data.breathingRate ?? null;
      let mappedMovementDetected: boolean | null = null;
      if (typeof data.movement === 'boolean') {
        mappedMovementDetected = data.movement;
      } else if (typeof data.movement === 'string') {
        mappedMovementDetected = data.movement.toUpperCase() !== 'NONE' && data.movement.toUpperCase() !== 'STILL';
      }

      const telemetryPayload = {
        deviceId,
        timestamp: data.timestamp,
        heartRate: data.heartRate ?? null,
        respirationRate: mappedRespirationRate,
        bodyTemperature: data.bodyTemperature ?? null,
        roomTemperature: data.roomTemperature ?? null,
        humidity: data.humidity ?? null,
        movementDetected: mappedMovementDetected,
        cryDetected: data.cryDetected ?? null,
        sleepStage: data.sleepStage ?? null,
        airQuality: data.airQuality ?? null,
        batteryLevel: data.batteryLevel ?? null,
      };

      // 4. Save to database
      const stored = await telemetryService.storeTelemetry(telemetryPayload, babyId);

      // 5. Update device registry status, lastSeen, and battery
      await prisma.device.update({
        where: { deviceId },
        data: {
          status: 'ONLINE',
          lastSeen: new Date(),
          ...(data.batteryLevel !== undefined && data.batteryLevel !== null && {
            battery: data.batteryLevel,
          }),
        },
      });

      // 6. Emit real-time updates via Socket.IO
      const wsManager = WebsocketServerManager.getInstance();
      wsManager.broadcastTelemetry(babyId, telemetryPayload);
      wsManager.broadcastDeviceStatus(babyId, deviceId, 'ONLINE', data.batteryLevel ?? undefined);

      // 7. Run alert engine
      const alertEngine = AlertEngine.getInstance();
      const timestampStr = data.timestamp;

      if (data.heartRate !== undefined && data.heartRate !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'heart_rate',
          type: 'heart_rate',
          value: data.heartRate,
          unit: '',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      if (mappedRespirationRate !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'breathing_rate',
          type: 'breathing_rate',
          value: mappedRespirationRate,
          unit: '',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      if (data.bodyTemperature !== undefined && data.bodyTemperature !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'body_temperature',
          type: 'body_temperature',
          value: data.bodyTemperature,
          unit: '°C',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      if (data.roomTemperature !== undefined && data.roomTemperature !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'room_temperature',
          type: 'room_temperature',
          value: data.roomTemperature,
          unit: '°C',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      if (data.humidity !== undefined && data.humidity !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'humidity',
          type: 'humidity',
          value: data.humidity,
          unit: '%',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      if (data.cryDetected !== undefined && data.cryDetected !== null) {
        await alertEngine.evaluateTelemetry({
          deviceId,
          sensorId: 'cry_detection',
          type: 'cry_detection',
          value: data.cryDetected ? 1.0 : 0.0,
          unit: '',
          timestamp: timestampStr,
          quality: 'good',
          battery: data.batteryLevel ?? undefined,
          signalStrength: data.signalStrength ?? 100,
          status: 'online',
          cradleId: deviceId,
          sequenceNumber: 0,
        });
      }

      return res.status(201).json({
        success: true,
        message: 'Telemetry ingested successfully.',
        data: stored,
      });

    } catch (e: any) {
      return res.status(500).json({
        success: false,
        message: e.message || 'Internal telemetry ingestion error.',
      });
    }
  }

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
