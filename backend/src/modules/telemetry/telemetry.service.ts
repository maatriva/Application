import { prisma } from '../../config/database';
import { TelemetryPayload as TelemetryPayloadType } from './telemetry.types';

export class TelemetryService {
  /**
   * Save incoming telemetry row to the database.
   */
  public async storeTelemetry(data: TelemetryPayloadType, babyId: string | null) {
    return await prisma.telemetry.create({
      data: {
        deviceId: data.deviceId,
        babyId: babyId,
        timestamp: new Date(data.timestamp),
        heartRate: data.heartRate ?? null,
        respirationRate: data.respirationRate ?? null,
        bodyTemperature: data.bodyTemperature ?? null,
        roomTemperature: data.roomTemperature ?? null,
        humidity: data.humidity ?? null,
        movementDetected: data.movementDetected ?? null,
        cryDetected: data.cryDetected ?? null,
        sleepStage: data.sleepStage ?? null,
        airQuality: data.airQuality ?? null,
        batteryLevel: data.batteryLevel ?? null,
      },
    });
  }

  /**
   * Get the latest telemetry reading for a baby. Verifies parent ownership.
   */
  public async getLatestReading(babyId: string, parentId: string) {
    await this.verifyBabyOwnership(babyId, parentId, 'VIEW_LATEST');

    const latest = await prisma.telemetry.findFirst({
      where: {
        babyId,
      },
      orderBy: {
        timestamp: 'desc',
      },
    });

    return latest || null;
  }

  /**
   * Get telemetry historical readings. Verifies parent ownership.
   */
  public async getHistory(
    babyId: string,
    parentId: string,
    filters: { from?: Date; to?: Date; limit?: number }
  ) {
    await this.verifyBabyOwnership(babyId, parentId, 'VIEW_HISTORY');

    const whereClause: any = {
      babyId,
    };

    if (filters.from || filters.to) {
      whereClause.timestamp = {};
      if (filters.from) {
        whereClause.timestamp.gte = filters.from;
      }
      if (filters.to) {
        whereClause.timestamp.lte = filters.to;
      }
    }

    const history = await prisma.telemetry.findMany({
      where: whereClause,
      orderBy: {
        timestamp: 'desc',
      },
      take: filters.limit || 100, // default limit is 100
    });

    return history;
  }

  /**
   * Helper method to verify baby ownership / caregiver access and existence.
   */
  private async verifyBabyOwnership(babyId: string, userId: string, action: 'VIEW_LATEST' | 'VIEW_HISTORY') {
    const baby = await prisma.baby.findFirst({
      where: {
        id: babyId,
        deletedAt: null,
      },
    });

    if (!baby) {
      const err: any = new Error('Baby profile not found.');
      err.statusCode = 404;
      throw err;
    }

    // 1. Primary parent has full access
    if (baby.parentId === userId) {
      return baby;
    }

    // 2. Caregiver check
    const caregiver = await prisma.caregiver.findFirst({
      where: {
        babyId,
        userId,
        status: 'accepted',
      },
    });

    if (!caregiver) {
      const err: any = new Error('Access denied to baby telemetry.');
      err.statusCode = 403;
      throw err;
    }

    // 3. Enforce Role restrictions
    const role = caregiver.accessLevel.toUpperCase(); // SECONDARY_PARENT, GRANDPARENT, BABYSITTER

    if (action === 'VIEW_HISTORY' && role === 'BABYSITTER') {
      const err: any = new Error('Access denied: Babysitters do not have access to telemetry history.');
      err.statusCode = 403;
      throw err;
    }

    return baby;
  }
}
