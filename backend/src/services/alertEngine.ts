import { prisma } from '../config/database';

export interface TelemetryPacket {
  deviceId: string;
  sensorId: string;
  type: string;
  value: any;
  unit: string;
  timestamp: string;
  quality: string;
  battery?: number;
  signalStrength: number;
  status: string;
  cradleId: string;
  sequenceNumber: number;
}

export interface AlertTrigger {
  deviceId: string;
  babyId: string | null;
  severity: string;
  type: string;
  message: string;
  value: number;
  thresholdLimit: number;
}

export class AlertEngine {
  private static instance: AlertEngine | null = null;

  public static getInstance(): AlertEngine {
    if (!AlertEngine.instance) {
      AlertEngine.instance = new AlertEngine();
    }
    return AlertEngine.instance;
  }

  // Cooldown store: key = babyId:deviceId:alertType, value = timestamp of last notification sent
  private cooldowns: Map<string, number> = new Map();
  private readonly cooldownPeriodMs = 120000; // 2 minutes cooldown between duplicate notifications

  // Callback hooks for runtime injections
  public onAlertTriggered?: (alert: any) => void;

  constructor() {
    if (!AlertEngine.instance) {
      AlertEngine.instance = this;
    }
  }

  /**
   * Main entry point to evaluate incoming telemetry packet against baby age-specific guidelines.
   */
  public async evaluateTelemetry(packet: TelemetryPacket): Promise<void> {
    const value = typeof packet.value === 'number' ? packet.value : parseFloat(packet.value?.toString() || '0');
    if (isNaN(value) || !Number.isFinite(value)) return;

    try {
      // 1. Resolve baby and their age in months from authoritative DeviceAssignment
      const assignment = await this.resolveBabyFromDevice(packet.deviceId);
      
      // Safety Rule: Unregistered/unpaired devices cannot trigger alerts for babies
      if (!assignment || !assignment.babyId) {
        return;
      }

      const babyId = assignment.babyId;
      const ageMonths = this.calculateAgeInMonths(assignment.birthDate);

      let alert: AlertTrigger | null = null;

      // 2. Run rule evaluations
      switch (packet.type) {
        case 'heart_rate':
        case 'HEART_RATE':
          alert = this.evaluateHeartRate(packet.deviceId, babyId, value, ageMonths);
          break;
        case 'breathing_rate':
        case 'respiration_rate':
          alert = this.evaluateBreathingRate(packet.deviceId, babyId, value, ageMonths);
          break;
        case 'body_temperature':
          alert = this.evaluateBodyTemp(packet.deviceId, babyId, value);
          break;
        case 'room_temperature':
          alert = this.evaluateRoomTemp(packet.deviceId, babyId, value);
          break;
        case 'gas_detection':
          alert = this.evaluateGasLevels(packet.deviceId, babyId, value);
          break;
        case 'spo2':
          alert = this.evaluateOxygenLevels(packet.deviceId, babyId, value);
          break;
        case 'cry_detection':
          alert = this.evaluateCryDetection(packet.deviceId, babyId, value);
          break;
      }

      // 3. Process and persist alert
      if (alert) {
        await this.handleTriggeredAlert(alert);
      }
    } catch (e) {
      console.error('Alert Engine evaluation failure:', e);
    }
  }

  private evaluateHeartRate(deviceId: string, babyId: string | null, hr: number, ageMonths: number): AlertTrigger | null {
    const isNewborn = ageMonths <= 3;
    const minSafe = isNewborn ? 100 : 90;
    const maxSafe = isNewborn ? 165 : 150;
    const criticalMin = isNewborn ? 70 : 60;
    const criticalMax = isNewborn ? 200 : 190;

    if (hr < criticalMin) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'low_heart_rate_emergency',
        message: `Emergency: Baby heart rate is extremely low (${hr} BPM).`,
        value: hr,
        thresholdLimit: criticalMin,
      };
    }
    if (hr > criticalMax) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'high_heart_rate_emergency',
        message: `Emergency: Baby heart rate is extremely high (${hr} BPM).`,
        value: hr,
        thresholdLimit: criticalMax,
      };
    }
    if (hr < minSafe) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'low_heart_rate_warning',
        message: `Warning: Baby heart rate is low (${hr} BPM).`,
        value: hr,
        thresholdLimit: minSafe,
      };
    }
    if (hr > maxSafe) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'high_heart_rate_warning',
        message: `Warning: Baby heart rate is elevated (${hr} BPM).`,
        value: hr,
        thresholdLimit: maxSafe,
      };
    }

    return null;
  }

  private evaluateBreathingRate(deviceId: string, babyId: string | null, br: number, ageMonths: number): AlertTrigger | null {
    const isNewborn = ageMonths <= 3;
    const minSafe = isNewborn ? 30 : 24;
    const maxSafe = isNewborn ? 60 : 40;
    const criticalMin = isNewborn ? 20 : 15;
    const criticalMax = isNewborn ? 80 : 60;

    if (br <= 0) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'apnea_emergency',
        message: 'Emergency apnea warning: Respiration flatlined (0 breaths).',
        value: br,
        thresholdLimit: minSafe,
      };
    }
    if (br < criticalMin) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'low_breathing_emergency',
        message: `Emergency: Respiration is critically low (${br} brpm).`,
        value: br,
        thresholdLimit: criticalMin,
      };
    }
    if (br > criticalMax) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'high_breathing_emergency',
        message: `Emergency: Respiration is critically high (${br} brpm).`,
        value: br,
        thresholdLimit: criticalMax,
      };
    }
    return null;
  }

  private evaluateBodyTemp(deviceId: string, babyId: string | null, temp: number): AlertTrigger | null {
    if (temp > 38.5) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'high_fever_emergency',
        message: `Emergency: Baby has a high fever (${temp}°C).`,
        value: temp,
        thresholdLimit: 38.5,
      };
    }
    if (temp < 35.0) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'hypothermia_emergency',
        message: `Emergency: Baby temperature is critically low (${temp}°C).`,
        value: temp,
        thresholdLimit: 35.0,
      };
    }
    if (temp > 37.8) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'fever_warning',
        message: `Warning: Baby has a mild fever (${temp}°C).`,
        value: temp,
        thresholdLimit: 37.8,
      };
    }
    return null;
  }

  private evaluateRoomTemp(deviceId: string, babyId: string | null, temp: number): AlertTrigger | null {
    if (temp > 26.0) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'room_hot_warning',
        message: `Warning: Nursery room temperature is too warm (${temp}°C).`,
        value: temp,
        thresholdLimit: 26.0,
      };
    }
    if (temp < 16.0) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'room_cold_warning',
        message: `Warning: Nursery room temperature is too cold (${temp}°C).`,
        value: temp,
        thresholdLimit: 16.0,
      };
    }
    return null;
  }

  private evaluateGasLevels(deviceId: string, babyId: string | null, gasPpm: number): AlertTrigger | null {
    if (gasPpm > 50) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'toxic_gas_emergency',
        message: `Emergency: Carbon Monoxide / Toxic gas leak detected (${gasPpm} ppm)!`,
        value: gasPpm,
        thresholdLimit: 50,
      };
    }
    if (gasPpm > 25) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'gas_elevated_warning',
        message: `Warning: Elevated gas levels detected (${gasPpm} ppm).`,
        value: gasPpm,
        thresholdLimit: 25,
      };
    }
    return null;
  }

  private evaluateOxygenLevels(deviceId: string, babyId: string | null, spo2: number): AlertTrigger | null {
    if (spo2 < 90) {
      return {
        deviceId,
        babyId,
        severity: 'emergency',
        type: 'hypoxia_emergency',
        message: `Emergency: Critically low blood oxygen level (${spo2}% SpO2).`,
        value: spo2,
        thresholdLimit: 90,
      };
    }
    if (spo2 < 94) {
      return {
        deviceId,
        babyId,
        severity: 'warning',
        type: 'hypoxia_warning',
        message: `Warning: Low blood oxygen level (${spo2}% SpO2).`,
        value: spo2,
        thresholdLimit: 94,
      };
    }
    return null;
  }

  private evaluateCryDetection(deviceId: string, babyId: string | null, value: number): AlertTrigger | null {
    if (value > 0) {
      return {
        deviceId,
        babyId,
        severity: 'HIGH',
        type: 'CRY_DETECTED',
        message: 'The system detected that the baby is crying. Please check on the baby.',
        value: 1.0,
        thresholdLimit: 1.0,
      };
    }
    return null;
  }

  private async handleTriggeredAlert(alert: AlertTrigger): Promise<void> {
    if (!alert.babyId) return;

    const cooldownKey = `${alert.babyId}:${alert.deviceId}:${alert.type}`;
    const now = Date.now();
    const lastTriggered = this.cooldowns.get(cooldownKey) || 0;

    // Deduplication cooldown: 45s for cry alert, 120s default for others
    const cooldownPeriod = alert.type === 'CRY_DETECTED' ? 45000 : this.cooldownPeriodMs;
    if (now - lastTriggered < cooldownPeriod) {
      return; // Skip duplicate spam
    }
    this.cooldowns.set(cooldownKey, now);

    try {
      // Persist alert to database
      const dbAlert = await prisma.alert.create({
        data: {
          deviceId: alert.deviceId,
          babyId: alert.babyId,
          severity: alert.severity === 'HIGH' ? 'danger' : alert.severity,
          type: alert.type,
          message: alert.message,
          value: alert.value,
          thresholdLimit: alert.thresholdLimit,
        },
      });

      // Broadcast real-time alert event
      if (this.onAlertTriggered) {
        const broadcastAlert = {
          ...dbAlert,
          alertId: dbAlert.id,
        };
        this.onAlertTriggered(broadcastAlert);
      }
    } catch (e) {
      console.error('Error persisting triggered alert:', e);
    }
  }

  private async resolveBabyFromDevice(deviceId: string): Promise<{ babyId: string; birthDate: Date } | null> {
    try {
      const assignment = await prisma.deviceAssignment.findFirst({
        where: { deviceId },
        include: {
          baby: true,
        },
      });
      if (!assignment || !assignment.baby || assignment.baby.deletedAt !== null) return null;
      return {
        babyId: assignment.babyId,
        birthDate: assignment.baby.birthDate,
      };
    } catch (e) {
      return null;
    }
  }

  private calculateAgeInMonths(birthDate: Date): number {
    const today = new Date();
    const yearsDiff = today.getFullYear() - birthDate.getFullYear();
    const monthsDiff = today.getMonth() - birthDate.getMonth();
    return yearsDiff * 12 + monthsDiff;
  }
}
