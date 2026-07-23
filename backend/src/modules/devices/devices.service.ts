import { prisma } from '../../config/database';

export class DevicesService {
  /**
   * Pair a cradle/sensor device.
   */
  public async pairDevice(data: {
    deviceId: string;
    deviceName: string;
    type: string;
    firmwareVersion?: string;
    protocol?: string;
    babyId: string;
  }) {
    // 1. Insert device registry if it does not exist, otherwise update status & name
    await prisma.device.upsert({
      where: { deviceId: data.deviceId },
      update: {
        paired: true,
        deviceName: data.deviceName,
      },
      create: {
        deviceId: data.deviceId,
        deviceName: data.deviceName,
        type: data.type,
        firmwareVersion: data.firmwareVersion || '1.0.0',
        protocol: data.protocol || 'Wi-Fi',
        paired: true,
      },
    });

    // 2. Map assignment to baby
    await prisma.deviceAssignment.upsert({
      where: {
        deviceId_babyId: {
          deviceId: data.deviceId,
          babyId: data.babyId,
        },
      },
      update: {},
      create: {
        deviceId: data.deviceId,
        babyId: data.babyId,
      },
    });

    return { message: 'Device paired successfully.', deviceId: data.deviceId, babyId: data.babyId };
  }

  /**
   * Fetch devices assigned to user's babies.
   */
  public async listDevices(userId: string) {
    const devices = await prisma.device.findMany({
      where: {
        assignments: {
          some: {
            baby: {
              OR: [
                { parentId: userId },
                {
                  caregivers: {
                    some: {
                      userId,
                      status: 'accepted',
                    },
                  },
                },
              ],
            },
          },
        },
      },
      include: {
        assignments: true,
      },
    });

    // Map output to match the format expected by the frontend
    return devices.map((d) => ({
      deviceId: d.deviceId,
      deviceName: d.deviceName,
      type: d.type,
      firmwareVersion: d.firmwareVersion,
      protocol: d.protocol,
      battery: d.battery,
      status: d.status,
      lastSeen: d.lastSeen,
      babyId: d.assignments[0]?.babyId || null,
    }));
  }

  /**
   * Get latest telemetry vitals.
   */
  public async getLatestTelemetry(deviceId: string) {
    const latest = await prisma.telemetry.findFirst({
      where: { deviceId },
      orderBy: { timestamp: 'desc' },
    });

    if (!latest) return [];

    const result = [];
    if (latest.heartRate !== null && latest.heartRate !== undefined) {
      result.push({ sensorType: 'heart_rate', value: latest.heartRate, unit: 'bpm', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.respirationRate !== null && latest.respirationRate !== undefined) {
      result.push({ sensorType: 'breathing_rate', value: latest.respirationRate, unit: 'bpm', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.bodyTemperature !== null && latest.bodyTemperature !== undefined) {
      result.push({ sensorType: 'body_temperature', value: latest.bodyTemperature, unit: '°C', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.roomTemperature !== null && latest.roomTemperature !== undefined) {
      result.push({ sensorType: 'room_temperature', value: latest.roomTemperature, unit: '°C', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.humidity !== null && latest.humidity !== undefined) {
      result.push({ sensorType: 'humidity', value: latest.humidity, unit: '%', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.airQuality !== null && latest.airQuality !== undefined) {
      result.push({ sensorType: 'air_quality', value: latest.airQuality, unit: 'AQI', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.batteryLevel !== null && latest.batteryLevel !== undefined) {
      result.push({ sensorType: 'battery_level', value: latest.batteryLevel, unit: '%', quality: 'good', timestamp: latest.timestamp });
    }
    return result;
  }

  /**
   * Fetch telemetry history for charts.
   */
  public async getTelemetryHistory(deviceId: string, sensorType: string, limit: number) {
    const history = await prisma.telemetry.findMany({
      where: {
        deviceId,
      },
      orderBy: {
        timestamp: 'desc',
      },
      take: limit,
    });

    const formatHistory = (h: any) => {
      let value: number | null = null;
      let unit = '';

      switch (sensorType) {
        case 'heart_rate':
          value = h.heartRate;
          unit = 'bpm';
          break;
        case 'breathing_rate':
        case 'respiration_rate':
          value = h.respirationRate;
          unit = 'bpm';
          break;
        case 'body_temperature':
          value = h.bodyTemperature;
          unit = '°C';
          break;
        case 'room_temperature':
          value = h.roomTemperature;
          unit = '°C';
          break;
        case 'humidity':
          value = h.humidity;
          unit = '%';
          break;
        case 'air_quality':
          value = h.airQuality;
          unit = 'AQI';
          break;
        case 'battery_level':
          value = h.batteryLevel;
          unit = '%';
          break;
      }

      return {
        timestamp: h.timestamp,
        value: value ?? 0,
        unit,
        quality: 'good',
      };
    };

    return history.map(formatHistory).reverse(); // chronology for charting
  }

  /**
   * Fetch alerts for a device.
   */
  public async getDeviceAlerts(deviceId: string, acknowledged: boolean) {
    const alerts = await prisma.alert.findMany({
      where: {
        deviceId,
        acknowledged,
      },
      orderBy: {
        timestamp: 'desc',
      },
    });

    return alerts.map((a) => ({
      id: a.id,
      severity: a.severity,
      type: a.type,
      message: a.message,
      value: a.value,
      thresholdLimit: a.thresholdLimit,
      timestamp: a.timestamp,
      acknowledged: a.acknowledged,
    }));
  }
}
