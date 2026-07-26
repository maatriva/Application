import { Request, Response } from 'express';
import { prisma } from '../../config/database';
import { AlertEngine } from '../../services/alertEngine';
import { TelemetrySubscriber } from '../../mqtt/telemetrySubscriber';
import { WebsocketServerManager } from '../../websocket/websocketServer';
import fs from 'fs';
import path from 'path';

// Instantiate simulator-specific AlertEngine
const alertEngine = new AlertEngine();
alertEngine.onAlertTriggered = (alert) => {
  console.log(`[DEBUG SIMULATOR] Alert triggered: [${alert.severity.toUpperCase()}] ${alert.message}`);
  if (alert.babyId) {
    WebsocketServerManager.getInstance().broadcastAlert(alert.babyId, alert);
  }
};

const subscriber = new TelemetrySubscriber(alertEngine);

export class DebugController {
  /**
   * Helper to resolve deviceId from babyId.
   */
  private static async resolveDeviceId(babyId: string): Promise<string> {
    const assignment = await prisma.deviceAssignment.findFirst({
      where: { babyId },
    });
    if (!assignment) {
      throw { statusCode: 404, message: `No active device assignment found for babyId: ${babyId}` };
    }
    return assignment.deviceId;
  }

  /**
   * POST /debug/telemetry
   */
  public static async submitTelemetry(req: Request, res: Response) {
    console.log('[DEBUG] Received simulated telemetry request');
    const {
      babyId,
      heartRate,
      breathingRate,
      bodyTemperature,
      roomTemperature,
      humidity,
      movement,
      cryDetected,
    } = req.body;

    if (!babyId) {
      return res.status(400).json({ success: false, message: 'babyId is required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);
      const telemetryPayload = {
        deviceId,
        timestamp: new Date().toISOString(),
        heartRate: heartRate !== undefined ? Number(heartRate) : null,
        respirationRate: breathingRate !== undefined ? Number(breathingRate) : null,
        bodyTemperature: bodyTemperature !== undefined ? Number(bodyTemperature) : null,
        roomTemperature: roomTemperature !== undefined ? Number(roomTemperature) : null,
        humidity: humidity !== undefined ? Number(humidity) : null,
        movementDetected: movement === true,
        cryDetected: cryDetected === true,
        airQuality: 50,
        batteryLevel: 100,
      };

      console.log(`[DEBUG] Forwarding simulated telemetry to pipeline for device ${deviceId}`);
      await subscriber.handleMessage(deviceId, JSON.stringify(telemetryPayload));

      res.json({
        success: true,
        message: 'Simulated telemetry processed through production pipeline.',
        data: telemetryPayload,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error processing debug telemetry.',
      });
    }
  }

  /**
   * POST /debug/alert
   */
  public static async submitAlert(req: Request, res: Response) {
    console.log('[DEBUG] Received simulated alert request');
    const { babyId, type, severity, value } = req.body;

    if (!babyId || !type || !severity) {
      return res.status(400).json({ success: false, message: 'babyId, type, and severity are required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);
      const thresholdLimit = type.toLowerCase().includes('temp') ? 38.0 : 120.0;

      const alert = await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: severity.toLowerCase(),
          type: type.toLowerCase(),
          message: `Simulated Alert: [${severity.toUpperCase()}] ${type.replace('_', ' ')}: value ${value || '--'}`,
          value: value !== undefined ? Number(value) : null,
          thresholdLimit,
        },
      });

      console.log(`[DEBUG] Alert created in DB and broadcasting to Socket.IO for room baby:${babyId}`);
      WebsocketServerManager.getInstance().broadcastAlert(babyId, alert);

      res.json({
        success: true,
        message: 'Simulated alert created and broadcast successfully.',
        data: alert,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error processing debug alert.',
      });
    }
  }

  /**
   * POST /debug/device/offline
   */
  public static async setDeviceOffline(req: Request, res: Response) {
    console.log('[DEBUG] Received offline simulation request');
    const { babyId } = req.body;

    if (!babyId) {
      return res.status(400).json({ success: false, message: 'babyId is required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);

      // 1. Update DB Status
      await prisma.device.update({
        where: { deviceId },
        data: {
          status: 'OFFLINE',
          lastSeen: new Date(),
        },
      });

      // 2. Create Offline Alert
      const alert = await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'device_offline',
          message: `Device ${deviceId} went offline.`,
        },
      });

      // 3. Emit Sockets
      WebsocketServerManager.getInstance().broadcastDeviceStatus(babyId, deviceId, 'OFFLINE');
      WebsocketServerManager.getInstance().broadcastAlert(babyId, alert);

      console.log(`[DEBUG] Device ${deviceId} set offline and broadcasted.`);

      res.json({
        success: true,
        message: 'Device offline simulation complete.',
        data: { deviceId, status: 'OFFLINE' },
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error executing offline simulation.',
      });
    }
  }

  /**
   * POST /debug/device/online
   */
  public static async setDeviceOnline(req: Request, res: Response) {
    console.log('[DEBUG] Received online simulation request');
    const { babyId } = req.body;

    if (!babyId) {
      return res.status(400).json({ success: false, message: 'babyId is required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);

      // 1. Update DB Status
      await prisma.device.update({
        where: { deviceId },
        data: {
          status: 'ONLINE',
          lastSeen: new Date(),
        },
      });

      // 2. Create Reconnect Alert
      const alert = await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'device_online',
          message: `Device ${deviceId} is reconnected.`,
        },
      });

      // 3. Emit Sockets
      WebsocketServerManager.getInstance().broadcastDeviceStatus(babyId, deviceId, 'ONLINE');
      WebsocketServerManager.getInstance().broadcastAlert(babyId, alert);

      console.log(`[DEBUG] Device ${deviceId} restored online and broadcasted.`);

      res.json({
        success: true,
        message: 'Device online simulation complete.',
        data: { deviceId, status: 'ONLINE' },
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error executing online simulation.',
      });
    }
  }

  /**
   * POST /debug/cry/start
   */
  public static async startCry(req: Request, res: Response) {
    console.log('[DEBUG] Received cry start simulation request');
    const { babyId } = req.body;

    if (!babyId) {
      return res.status(400).json({ success: false, message: 'babyId is required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);

      // 1. Send Telemetry update via subscriber (realistic elevated stats)
      const telemetryPayload = {
        deviceId,
        timestamp: new Date().toISOString(),
        heartRate: 142,
        respirationRate: 38,
        bodyTemperature: 37.1,
        roomTemperature: 22.0,
        humidity: 50.0,
        movementDetected: true,
        cryDetected: true,
        airQuality: 45,
        batteryLevel: 99,
      };

      await subscriber.handleMessage(deviceId, JSON.stringify(telemetryPayload));

      // 2. Explicitly trigger Cry Warning Alert
      const alert = await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'warning',
          type: 'cry_detected',
          message: `Acoustic Cry Analytics: Continuous cry detected inside cradle.`,
        },
      });

      WebsocketServerManager.getInstance().broadcastAlert(babyId, alert);
      console.log(`[DEBUG] Cry start event simulated for baby ${babyId}`);

      res.json({
        success: true,
        message: 'Baby cry simulation started.',
        data: alert,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error starting cry simulation.',
      });
    }
  }

  /**
   * POST /debug/cry/stop
   */
  public static async stopCry(req: Request, res: Response) {
    console.log('[DEBUG] Received cry stop simulation request');
    const { babyId } = req.body;

    if (!babyId) {
      return res.status(400).json({ success: false, message: 'babyId is required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);

      // Send Telemetry update via subscriber representing calm metrics
      const telemetryPayload = {
        deviceId,
        timestamp: new Date().toISOString(),
        heartRate: 110,
        respirationRate: 26,
        bodyTemperature: 36.8,
        roomTemperature: 22.0,
        humidity: 50.0,
        movementDetected: false,
        cryDetected: false,
        airQuality: 45,
        batteryLevel: 99,
      };

      await subscriber.handleMessage(deviceId, JSON.stringify(telemetryPayload));
      console.log(`[DEBUG] Cry stop event simulated for baby ${babyId}`);

      res.json({
        success: true,
        message: 'Baby cry simulation stopped (calm telemetry sent).',
        data: telemetryPayload,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error stopping cry simulation.',
      });
    }
  }

  /**
   * POST /debug/sensor/failure
   */
  public static async triggerSensorFailure(req: Request, res: Response) {
    console.log('[DEBUG] Received sensor failure simulation request');
    const { babyId, sensor } = req.body;

    if (!babyId || !sensor) {
      return res.status(400).json({ success: false, message: 'babyId and sensor are required.' });
    }

    try {
      const deviceId = await DebugController.resolveDeviceId(babyId);

      const alert = await prisma.alert.create({
        data: {
          deviceId,
          babyId,
          severity: 'emergency',
          type: 'sensor_failure',
          message: `Critical Error: Hardware failure detected on ${sensor} sensor module!`,
        },
      });

      WebsocketServerManager.getInstance().broadcastAlert(babyId, alert);
      console.log(`[DEBUG] Sensor failure alert generated for ${sensor}`);

      res.json({
        success: true,
        message: `Sensor failure simulated for ${sensor}.`,
        data: alert,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Error simulating sensor failure.',
      });
    }
  }

  /**
   * GET /debug/status
   */
  public static async getStatus(req: Request, res: Response) {
    console.log('[DEBUG] Status check requested');
    try {
      const connectedBabies = await prisma.baby.findMany({
        where: { deviceAssignments: { some: {} } },
        select: { id: true, name: true },
      });

      const connectedDevices = await prisma.device.findMany({
        select: { deviceId: true, deviceName: true, status: true },
      });

      const socketClientsCount = WebsocketServerManager.getInstance().getConnectedClientsCount();

      const recentAlerts = await prisma.alert.findMany({
        take: 5,
        orderBy: { timestamp: 'desc' },
      });

      const recentTelemetry = await prisma.telemetry.findMany({
        take: 5,
        orderBy: { timestamp: 'desc' },
      });

      res.json({
        success: true,
        message: 'Debug status summary retrieved.',
        data: {
          simulatorEnabled: true,
          connectedBabies,
          connectedDevices,
          socketClientsCount,
          recentAlerts,
          recentTelemetry,
        },
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Error retrieving debug status.',
      });
    }
  }

  /**
   * DELETE /debug/reset (and POST /debug/reset)
   */
  public static async resetData(req: Request, res: Response) {
    console.log('[DEBUG] Reset database data requested');
    try {
      // Deletes only development-generated logs (Telemetry and Alerts)
      const telemetryCount = await prisma.telemetry.deleteMany({});
      const alertCount = await prisma.alert.deleteMany({});

      res.json({
        success: true,
        message: 'Development telemetry and alerts cleared successfully.',
        data: {
          telemetryDeleted: telemetryCount.count,
          alertsDeleted: alertCount.count,
        },
      });
    } catch (e: any) {
      res.status(500).json({
        success: false,
        message: e.message || 'Error resetting debug database data.',
      });
    }
  }

  /**
   * GET /debug/camera-simulator
   */
  public static async cameraSimulator(req: Request, res: Response) {
    try {
      const paths = [
        path.join(__dirname, 'camera.html'),
        path.join(process.cwd(), 'src/modules/debug/camera.html'),
        path.join(process.cwd(), 'backend/src/modules/debug/camera.html'),
      ];

      let htmlContent = '';
      for (const p of paths) {
        if (fs.existsSync(p)) {
          htmlContent = fs.readFileSync(p, 'utf8');
          break;
        }
      }

      if (!htmlContent) {
        throw new Error('camera.html not found in searched locations.');
      }

      res.setHeader('Content-Type', 'text/html');
      res.status(200).send(htmlContent);
    } catch (e: any) {
      res.status(500).send('Error loading camera simulator: ' + e.message);
    }
  }
}
