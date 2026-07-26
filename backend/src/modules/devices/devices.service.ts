import { prisma } from '../../config/database';
import crypto from 'crypto';

export class DevicesService {
  /**
   * Register a new device.
   */
  public async registerDevice(data: {
    deviceId: string;
    deviceName: string;
    type: string;
    registrationKey?: string;
    firmwareVersion?: string;
    protocol?: string;
  }) {
    const registrationKey = data.registrationKey || `REG-${crypto.randomBytes(6).toString('hex').toUpperCase()}`;

    // Check if device already exists with deviceId or registrationKey
    const existing = await prisma.device.findFirst({
      where: {
        OR: [
          { deviceId: data.deviceId },
          { registrationKey: registrationKey },
        ],
      },
    });

    if (existing) {
      const error: any = new Error('Device with this ID or Registration Key already exists.');
      error.statusCode = 400;
      throw error;
    }

    return await prisma.device.create({
      data: {
        deviceId: data.deviceId,
        deviceName: data.deviceName,
        type: data.type,
        registrationKey: registrationKey,
        firmwareVersion: data.firmwareVersion || '1.0.0',
        protocol: data.protocol || 'Wi-Fi',
        paired: false,
        status: 'UNPAIRED',
      },
    });
  }

  /**
   * Pair a cradle/sensor device using registration key.
   */
  public async pairDevice(data: {
    registrationKey: string;
    babyId: string;
    userId: string;
  }) {
    // 1. Verify baby exists
    const baby = await prisma.baby.findUnique({
      where: { id: data.babyId },
    });

    if (!baby || baby.deletedAt !== null) {
      const error: any = new Error('Baby not found.');
      error.statusCode = 404;
      throw error;
    }

    // 2. Verify baby access (owner is userId)
    if (baby.parentId !== data.userId) {
      const error: any = new Error('Unauthorized baby access.');
      error.statusCode = 403;
      throw error;
    }

    // 3. Find registered device by registrationKey
    const device = await prisma.device.findUnique({
      where: { registrationKey: data.registrationKey },
    });

    if (!device) {
      const error: any = new Error('Invalid registration key.');
      error.statusCode = 404;
      throw error;
    }

    // 4. Verify device is not already paired
    if (device.paired) {
      const error: any = new Error('Device is already paired.');
      error.statusCode = 400;
      throw error;
    }

    // 5. Associate device with baby via DeviceAssignment
    await prisma.deviceAssignment.create({
      data: {
        deviceId: device.deviceId,
        babyId: data.babyId,
      },
    });

    // 6. Update device paired status to true and status to PAIRED
    const updatedDevice = await prisma.device.update({
      where: { deviceId: device.deviceId },
      data: {
        paired: true,
        status: 'PAIRED',
        lastSeen: new Date(),
      },
    });

    // 7. Return the updated device information
    return {
      deviceId: updatedDevice.deviceId,
      deviceName: updatedDevice.deviceName,
      type: updatedDevice.type,
      firmwareVersion: updatedDevice.firmwareVersion,
      protocol: updatedDevice.protocol,
      battery: updatedDevice.battery,
      status: updatedDevice.status,
      lastSeen: updatedDevice.lastSeen,
      babyId: data.babyId,
    };
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
    if (latest.sleepStage !== null && latest.sleepStage !== undefined) {
      let numericVal = 0;
      if (latest.sleepStage === 'Light') numericVal = 1;
      else if (latest.sleepStage === 'Deep') numericVal = 2;
      else if (latest.sleepStage === 'REM') numericVal = 3;
      result.push({ sensorType: 'sleep_stage', value: numericVal, unit: latest.sleepStage, quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.cryDetected !== null && latest.cryDetected !== undefined) {
      result.push({ sensorType: 'cry_detection', value: latest.cryDetected ? 1.0 : 0.0, unit: '', quality: 'good', timestamp: latest.timestamp });
    }
    if (latest.movementDetected !== null && latest.movementDetected !== undefined) {
      result.push({ sensorType: 'movement_detection', value: latest.movementDetected ? 1.0 : 0.0, unit: '', quality: 'good', timestamp: latest.timestamp });
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
      severity: a.severity === 'danger' && a.type === 'CRY_DETECTED' ? 'HIGH' : a.severity,
      type: a.type,
      message: a.message,
      value: a.value,
      thresholdLimit: a.thresholdLimit,
      timestamp: a.timestamp,
      acknowledged: a.acknowledged,
    }));
  }

  /**
   * Rename a device.
   */
  public async renameDevice(deviceId: string, newName: string) {
    return await prisma.device.update({
      where: { deviceId },
      data: { deviceName: newName },
    });
  }

  /**
   * Reassign device to another baby.
   */
  public async reassignBaby(deviceId: string, babyId: string) {
    // Delete existing assignments first
    await prisma.deviceAssignment.deleteMany({
      where: { deviceId },
    });
    // Create new assignment
    return await prisma.deviceAssignment.create({
      data: { deviceId, babyId },
    });
  }

  /**
   * Unpair a device.
   */
  public async unpairDevice(deviceId: string) {
    // Delete assignments
    await prisma.deviceAssignment.deleteMany({
      where: { deviceId },
    });
    // Update paired status
    return await prisma.device.update({
      where: { deviceId },
      data: { paired: false },
    });
  }
}
