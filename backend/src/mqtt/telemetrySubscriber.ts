import { prisma } from '../config/database';
import { TelemetryService } from '../modules/telemetry/telemetry.service';
import { TelemetryPayloadSchema } from '../modules/telemetry/telemetry.validation';
import { AlertEngine, TelemetryPacket } from '../services/alertEngine';
import { WebsocketServerManager } from '../websocket/websocketServer';

const telemetryService = new TelemetryService();

export class TelemetrySubscriber {
  private alertEngine: AlertEngine;

  constructor(alertEngine: AlertEngine) {
    this.alertEngine = alertEngine;
  }

  /**
   * Main entry point to handle incoming telemetry MQTT payload.
   */
  public async handleMessage(deviceId: string, payloadStr: string): Promise<void> {
    try {
      const rawPayload = JSON.parse(payloadStr);

      // 1. Validate payload using Zod
      const parseResult = TelemetryPayloadSchema.safeParse(rawPayload);
      if (!parseResult.success) {
        console.warn(`[TelemetrySubscriber] Validation failed for device ${deviceId}:`, parseResult.error.issues.map((err: any) => err.message));
        return;
      }

      const telemetryData = parseResult.data;

      const cleanTopicDeviceId = deviceId.trim();
      const cleanPayloadDeviceId = telemetryData.deviceId.trim();

      // 2. Verify the payload deviceId matches the topic deviceId
      if (cleanPayloadDeviceId !== cleanTopicDeviceId) {
        console.warn(`[TelemetrySubscriber] Device ID mismatch between topic and payload. Topic: "${cleanTopicDeviceId}", Payload: "${cleanPayloadDeviceId}". Rejecting packet.`);
        return;
      }
      // 3. Database Lookup: Verify or auto-create the Device model using deviceId
      let device = await prisma.device.findUnique({
        where: { deviceId: cleanTopicDeviceId },
      });

      if (!device) {
        device = await prisma.device.create({
          data: {
            deviceId: cleanTopicDeviceId,
            deviceName: `Smart Cradle (${cleanTopicDeviceId})`,
            type: 'Smart Cradle',
            registrationKey: `REG-${cleanTopicDeviceId}`,
            firmwareVersion: '1.0.0',
            protocol: 'MQTT',
            paired: false,
            status: 'ONLINE',
          },
        });
      }

      // 4. Find or auto-create linked baby assignment
      let assignment = await prisma.deviceAssignment.findFirst({
        where: { deviceId: cleanTopicDeviceId },
      });

      if (!assignment) {
        const baby = await prisma.baby.findFirst({
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
        });
        if (baby) {
          assignment = await prisma.deviceAssignment.create({
            data: {
              deviceId: cleanTopicDeviceId,
              babyId: baby.id,
            },
          });
          await prisma.device.update({
            where: { deviceId: cleanTopicDeviceId },
            data: { paired: true, status: 'PAIRED' },
          });
        }
      }

      const babyId = assignment?.babyId || null;

      // 5. Store telemetry in dedicated table using clean ID
      await telemetryService.storeTelemetry({
        ...telemetryData,
        deviceId: cleanTopicDeviceId,
      }, babyId);

      if (babyId) {
        WebsocketServerManager.getInstance().broadcastTelemetry(babyId, telemetryData);
      }

      // 7. Update device registry status = ONLINE, lastSeen, and battery level
      await prisma.device.update({
        where: { deviceId: cleanTopicDeviceId },
        data: {
          status: 'ONLINE',
          lastSeen: new Date(),
          ...(telemetryData.batteryLevel !== undefined && telemetryData.batteryLevel !== null && {
            battery: telemetryData.batteryLevel,
          }),
        },
      });
      console.log(`[TelemetrySubscriber] Device registry updated: Device ${cleanTopicDeviceId} status set to ONLINE.`);

      if (babyId) {
        WebsocketServerManager.getInstance().broadcastDeviceStatus(
          babyId,
          cleanTopicDeviceId,
          'ONLINE',
          telemetryData.batteryLevel ?? undefined
        );
      }

      // 8. Route sensor metrics to the Alert Engine to trigger safety alerts
      const timestampStr = telemetryData.timestamp;

      if (telemetryData.heartRate !== undefined && telemetryData.heartRate !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'heart_rate', telemetryData.heartRate, timestampStr);
      }
      if (telemetryData.respirationRate !== undefined && telemetryData.respirationRate !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'breathing_rate', telemetryData.respirationRate, timestampStr);
      }
      if (telemetryData.bodyTemperature !== undefined && telemetryData.bodyTemperature !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'body_temperature', telemetryData.bodyTemperature, timestampStr);
      }
      if (telemetryData.roomTemperature !== undefined && telemetryData.roomTemperature !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'room_temperature', telemetryData.roomTemperature, timestampStr);
      }
      if (telemetryData.humidity !== undefined && telemetryData.humidity !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'humidity', telemetryData.humidity, timestampStr);
      }
      if (telemetryData.cryDetected !== undefined && telemetryData.cryDetected !== null) {
        await this.evaluateMetric(cleanTopicDeviceId, 'cry_detection', telemetryData.cryDetected ? 1.0 : 0.0, timestampStr);
      }

    } catch (e) {
      console.error(`[TelemetrySubscriber] Error processing MQTT telemetry message for device ${deviceId}:`, e);
    }
  }

  /**
   * Helper to map a metric and evaluate it in the AlertEngine
   */
  private async evaluateMetric(
    deviceId: string,
    type: string,
    value: number,
    timestamp: string
  ): Promise<void> {
    const packet: TelemetryPacket = {
      deviceId,
      sensorId: type,
      type,
      value,
      unit: type === 'body_temperature' || type === 'room_temperature' ? '°C' : type === 'humidity' ? '%' : '',
      timestamp,
      quality: 'good',
      battery: 100,
      signalStrength: 100,
      status: 'online',
      cradleId: deviceId,
      sequenceNumber: 0,
    };

    try {
      await this.alertEngine.evaluateTelemetry(packet);
    } catch (e) {
      console.error(`[TelemetrySubscriber] Alert Engine evaluation failed for metric ${type} on device ${deviceId}:`, e);
    }
  }
}
