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

      // Detailed logs: Step 1 (Topic/Payload IDs and DB Lookup Value)
      console.log(`Topic Device ID: ${cleanTopicDeviceId}`);
      console.log(`Payload Device ID: ${cleanPayloadDeviceId}`);
      console.log(`Database lookup value: ${cleanTopicDeviceId}`);

      // 3. Database Lookup: Verify the Device model using correct unique field (deviceId)
      const device = await prisma.device.findUnique({
        where: { deviceId: cleanTopicDeviceId },
      });

      console.log(`Device found: ${device ? 'Yes' : 'No'}`);

      // 4. Reject unknown devices with meaningful logs
      if (!device) {
        const availableDevices = await prisma.device.findMany({ select: { deviceId: true } });
        const availableIds = availableDevices.map((d) => d.deviceId).join(', ');
        console.warn(`Device not found.\nLookup field: deviceId\nLookup value: ${cleanTopicDeviceId}\nAvailable Device IDs: ${availableIds}`);
        return;
      }

      // 5. Find linked baby assignment using the same identifier
      const assignment = await prisma.deviceAssignment.findFirst({
        where: { deviceId: cleanTopicDeviceId },
      });
      const babyId = assignment?.babyId || null;

      console.log(`Assignment found: ${assignment ? 'Yes' : 'No'}`);

      // 6. Store telemetry in dedicated table using clean ID
      await telemetryService.storeTelemetry({
        ...telemetryData,
        deviceId: cleanTopicDeviceId,
      }, babyId);
      console.log(`Telemetry stored successfully.`);

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
