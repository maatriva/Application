import { prisma } from '../../config/database';
import crypto from 'crypto';

export class DevicesService {
  /**
   * Helper to verify if user (Parent or Caregiver) has authorized access to a device.
   */
  public async verifyUserDeviceAccess(userId: string, userRole: string, deviceId: string): Promise<boolean> {
    if (userRole === 'ADMIN') return true;

    const assignment = await prisma.deviceAssignment.findFirst({
      where: { deviceId },
      include: {
        baby: true,
      },
    });

    if (!assignment || !assignment.baby || assignment.baby.deletedAt !== null) {
      return false; // Unassigned/unpaired or deleted devices cannot be accessed by non-admins
    }

    if (userRole === 'PARENT' && assignment.baby.parentId === userId) {
      return true;
    }

    if (userRole === 'CAREGIVER') {
      const now = new Date();
      const activeTemp = await (prisma as any).temporaryCaregiverPermission.findFirst({
        where: {
          caregiverId: userId,
          babyId: assignment.babyId,
          revoked: false,
          status: 'ACTIVE',
          expiresAt: { gt: now },
        },
      });
      if (activeTemp) return true;

      const activeCg = await prisma.caregiver.findFirst({
        where: {
          userId,
          babyId: assignment.babyId,
          status: 'accepted',
        },
      });
      if (activeCg) return true;
    }

    return false;
  }

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
      // Idempotent: if existing, return device safely
      return existing;
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
      const error: any = new Error('Baby profile not found.');
      error.statusCode = 404;
      throw error;
    }

    // 2. Verify baby access (owner is userId)
    if (baby.parentId !== data.userId) {
      const error: any = new Error('Access denied: Only the baby owner can pair a device.');
      error.statusCode = 403;
      throw error;
    }

    // 3. Find registered device by registrationKey or deviceId
    let device = await prisma.device.findFirst({
      where: {
        OR: [
          { registrationKey: data.registrationKey },
          { deviceId: data.registrationKey },
        ],
      },
      include: {
        assignments: {
          include: { baby: true },
        },
      },
    });

    if (!device) {
      // Auto-register new cradle device on the fly for seamless pairing
      const devId = data.registrationKey.startsWith('DEV-') || data.registrationKey.startsWith('CRADLE-')
        ? data.registrationKey
        : `CRADLE-${data.registrationKey}`;

      device = await prisma.device.create({
        data: {
          deviceId: devId,
          deviceName: `Smart Cradle (${data.registrationKey})`,
          type: 'Smart Cradle',
          registrationKey: data.registrationKey,
          firmwareVersion: '1.0.0',
          protocol: 'Wi-Fi',
          paired: false,
          status: 'UNPAIRED',
        },
        include: {
          assignments: {
            include: { baby: true },
          },
        },
      });
    }

    // Prevent device takeover: check if device is already paired to another parent's baby
    if (device.assignments && device.assignments.length > 0) {
      const existingAssignment = device.assignments[0];
      if (existingAssignment.baby && existingAssignment.baby.parentId !== data.userId) {
        const error: any = new Error("Device is already paired to another parent's baby profile. It must be unpaired by its owner first.");
        error.statusCode = 403;
        throw error;
      }
    }

    // 4. Re-bind device assignment (delete any prior assignments for this device)
    await prisma.deviceAssignment.deleteMany({
      where: { deviceId: device.deviceId },
    });

    await prisma.deviceAssignment.create({
      data: {
        deviceId: device.deviceId,
        babyId: data.babyId,
      },
    });

    // 5. Update device paired status to true and status to PAIRED
    const updatedDevice = await prisma.device.update({
      where: { deviceId: device.deviceId },
      data: {
        paired: true,
        status: 'PAIRED',
        lastSeen: new Date(),
      },
    });

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
  public async getLatestTelemetry(deviceId: string, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: You do not have permission to view telemetry for this device.');
      error.statusCode = 403;
      throw error;
    }

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
  public async getTelemetryHistory(deviceId: string, sensorType: string, limit: number, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: You do not have permission to view telemetry history for this device.');
      error.statusCode = 403;
      throw error;
    }

    const history = await prisma.telemetry.findMany({
      where: { deviceId },
      orderBy: { timestamp: 'desc' },
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

    return history.map(formatHistory).reverse();
  }

  /**
   * Fetch alerts for a device.
   */
  public async getDeviceAlerts(deviceId: string, acknowledged: boolean, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: You do not have permission to view alerts for this device.');
      error.statusCode = 403;
      throw error;
    }

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
  public async renameDevice(deviceId: string, newName: string, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: Only the device owner can rename this device.');
      error.statusCode = 403;
      throw error;
    }

    return await prisma.device.update({
      where: { deviceId },
      data: { deviceName: newName },
    });
  }

  /**
   * Reassign device to another baby.
   */
  public async reassignBaby(deviceId: string, babyId: string, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: Only the device owner can reassign this device.');
      error.statusCode = 403;
      throw error;
    }

    const newBaby = await prisma.baby.findUnique({ where: { id: babyId } });
    if (!newBaby || newBaby.parentId !== userId) {
      const error: any = new Error('Access denied: Target baby must belong to you.');
      error.statusCode = 403;
      throw error;
    }

    await prisma.deviceAssignment.deleteMany({
      where: { deviceId },
    });

    return await prisma.deviceAssignment.create({
      data: { deviceId, babyId },
    });
  }

  /**
   * Unpair a device.
   */
  public async unpairDevice(deviceId: string, userId: string, userRole: string) {
    const isAuthorized = await this.verifyUserDeviceAccess(userId, userRole, deviceId);
    if (!isAuthorized) {
      const error: any = new Error('Access denied: Only the device owner can unpair this device.');
      error.statusCode = 403;
      throw error;
    }

    await prisma.deviceAssignment.deleteMany({
      where: { deviceId },
    });

    return await prisma.device.update({
      where: { deviceId },
      data: { paired: false, status: 'UNPAIRED' },
    });
  }
}
