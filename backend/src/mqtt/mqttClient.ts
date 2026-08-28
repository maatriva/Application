import mqtt, { MqttClient } from 'mqtt';
import { prisma } from '../config/database';
import { env } from '../config/env';
import { AlertEngine } from '../services/alertEngine';
import { TelemetrySubscriber } from './telemetrySubscriber';
import { WebsocketServerManager } from '../websocket/websocketServer';

export class MqttClientManager {
  private client?: MqttClient;
  private alertEngine: AlertEngine;
  private telemetrySubscriber: TelemetrySubscriber;
  private connectionStatus: 'connected' | 'disconnected' | 'reconnecting' = 'disconnected';

  constructor(alertEngine: AlertEngine) {
    this.alertEngine = alertEngine;
    this.telemetrySubscriber = new TelemetrySubscriber(alertEngine);
  }

  public getStatus(): 'connected' | 'disconnected' | 'reconnecting' {
    return this.connectionStatus;
  }

  /**
   * Initializes connections and subscribes to telemetry.
   */
  public connect(): void {
    const url = `mqtts://${env.MQTT_HOST}:${env.MQTT_PORT}`;
    console.log(`Connecting to MQTT Broker at ${url}...`);

    this.client = mqtt.connect(url, {
      clientId: env.MQTT_CLIENT_ID,
      username: env.MQTT_USERNAME,
      password: env.MQTT_PASSWORD,
      clean: true,
      reconnectPeriod: 5000, // auto reconnect every 5s
    });

    this.client.on('connect', async () => {
      this.connectionStatus = 'connected';
      console.log('✓ MQTT connected');

      // Print all registered devices
      try {
        const devices = await prisma.device.findMany({ select: { deviceId: true } });
        console.log('Registered devices:\n' + devices.map((d) => d.deviceId).join('\n'));
      } catch (err) {
        console.error('Failed to log registered devices on startup:', err);
      }

      // Subscribe to telemetry streams from all devices
      this.client?.subscribe('devices/+/telemetry', { qos: 0 }, (err) => {
        if (err) {
          console.error('MQTT subscription failed:', err);
        } else {
          console.log('Subscribed to topic: devices/+/telemetry');
        }
      });

      // Subscribe to device status topics (online/offline announcements)
      this.client?.subscribe('devices/+/status', { qos: 1 });
    });

    this.client.on('message', async (topic, message) => {
      try {
        const payloadStr = message.toString();
        const topicParts = topic.split('/');
        const deviceId = topicParts[1];

        if (topic.endsWith('/telemetry')) {
          await this.handleTelemetryMessage(deviceId, payloadStr);
        } else if (topic.endsWith('/status')) {
          await this.handleStatusMessage(deviceId, payloadStr);
        }
      } catch (e) {
        console.error(`Error processing MQTT message on topic ${topic}:`, e);
      }
    });

    this.client.on('reconnect', () => {
      this.connectionStatus = 'reconnecting';
      console.log('MQTT Client reconnecting...');
    });

    this.client.on('error', (err) => {
      this.connectionStatus = 'disconnected';
      console.error('MQTT Client connection error:', err);
    });

    this.client.on('offline', () => {
      this.connectionStatus = 'disconnected';
      console.warn('MQTT Client went offline.');
    });

    this.client.on('close', () => {
      this.connectionStatus = 'disconnected';
    });
  }

  public disconnect(): void {
    if (this.client) {
      this.client.end();
      this.connectionStatus = 'disconnected';
      console.log('MQTT Client disconnected.');
    }
  }

  private async handleTelemetryMessage(deviceId: string, payloadStr: string): Promise<void> {
    await this.telemetrySubscriber.handleMessage(deviceId, payloadStr);
  }

  private async handleStatusMessage(deviceId: string, payloadStr: string): Promise<void> {
    try {
      const data = JSON.parse(payloadStr);
      const status = data.status || 'offline';

      // Update registry device status using Prisma
      await prisma.device.update({
        where: { deviceId },
        data: {
          status,
          lastSeen: new Date(),
        },
      });

      console.log(`Device registry updated: Device ${deviceId} is ${status}.`);

      // Find babyId for this device assignment
      const assignment = await prisma.deviceAssignment.findFirst({
        where: { deviceId },
      });
      if (assignment) {
        WebsocketServerManager.getInstance().broadcastDeviceStatus(
          assignment.babyId,
          deviceId,
          status
        );
      }
    } catch (e) {
      console.error(`Error updating status for device ${deviceId}:`, e);
    }
  }

  /**
   * Publishes message to the broker (commands or system configs).
   */
  public publish(topic: string, payload: any, qos: 0 | 1 | 2 = 0): void {
    if (this.client?.connected) {
      const payloadStr = typeof payload === 'string' ? payload : JSON.stringify(payload);
      this.client.publish(topic, payloadStr, { qos, retain: false });
    } else {
      console.warn(`MQTT client offline. Cannot publish to topic: ${topic}`);
    }
  }
}
