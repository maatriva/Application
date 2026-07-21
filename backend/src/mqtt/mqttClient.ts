import mqtt, { MqttClient } from 'mqtt';
import { Pool } from 'pg';
import { config } from '../config/config';
import { AlertEngine, TelemetryPacket } from '../services/alertEngine';

export class MqttClientManager {
  private client?: MqttClient;
  private dbPool: Pool;
  private alertEngine: AlertEngine;

  constructor(dbPool: Pool, alertEngine: AlertEngine) {
    this.dbPool = dbPool;
    this.alertEngine = alertEngine;
  }

  /**
   * Initializes connections and subscribes to telemetry.
   */
  public connect(): void {
    const url = `mqtt://${config.mqttHost}:${config.mqttPort}`;
    console.log(`Connecting to MQTT Broker at ${url}...`);

    this.client = mqtt.connect(url, {
      clientId: config.mqttClientId,
      username: config.mqttUsername,
      password: config.mqttPassword,
      clean: true,
      reconnectPeriod: 5000, // auto reconnect every 5s
    });

    this.client.on('connect', () => {
      console.log('Connected to MQTT Broker successfully.');
      
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

    this.client.on('error', (err) => {
      console.error('MQTT Client connection error:', err);
    });

    this.client.on('offline', () => {
      console.warn('MQTT Client went offline.');
    });
  }

  public disconnect(): void {
    if (this.client) {
      this.client.end();
      console.log('MQTT Client disconnected.');
    }
  }

  private async handleTelemetryMessage(deviceId: string, payloadStr: string): Promise<void> {
    const data = JSON.parse(payloadStr);

    // Validate payload shape
    if (!data.type || data.value === undefined) {
      console.warn(`Invalid telemetry payload from device ${deviceId}`);
      return;
    }

    const packet: TelemetryPacket = {
      deviceId: deviceId,
      sensorId: data.sensorId || 'unknown',
      type: data.type,
      value: data.value,
      unit: data.unit || '',
      timestamp: data.timestamp || new Date().toISOString(),
      quality: data.quality || 'good',
      battery: data.battery,
      signalStrength: data.signalStrength || 0,
      status: data.status || 'online',
      cradleId: data.cradleId || 'unknown',
      sequenceNumber: data.sequenceNumber || 0,
    };

    // 1. Persist to TimescaleDB partitioned hypertable
    try {
      await this.dbPool.query(
        `INSERT INTO telemetry (timestamp, device_id, baby_id, sensor_type, value, unit, quality, battery, signal_strength)
         VALUES ($1, $2, (SELECT baby_id FROM device_assignments WHERE device_id = $2 LIMIT 1), $3, $4, $5, $6, $7, $8)`,
        [
          packet.timestamp,
          packet.deviceId,
          packet.type,
          typeof packet.value === 'number' ? packet.value : 0, // Fallback if non-numeric value
          packet.unit,
          packet.quality,
          packet.battery,
          packet.signalStrength,
        ]
      );
    } catch (e) {
      console.error(`Database insert failed for telemetry on device ${deviceId}:`, e);
    }

    // 2. Run Alert Engine Rules
    await this.alertEngine.evaluateTelemetry(packet);
  }

  private async handleStatusMessage(deviceId: string, payloadStr: string): Promise<void> {
    try {
      const data = JSON.parse(payloadStr);
      const status = data.status || 'offline';

      // Update registry device status
      await this.dbPool.query(
        `UPDATE devices SET status = $1, last_seen = NOW() WHERE device_id = $2`,
        [status, deviceId]
      );
      
      console.log(`Device registry updated: Device ${deviceId} is ${status}.`);
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
