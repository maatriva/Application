import { prisma } from '../../config/database';
import { CreateBabyInput, UpdateBabyInput } from './baby.types';

export class BabyService {
  /**
   * Create a new baby profile belonging to the parent.
   */
  public async createBaby(parentId: string, data: CreateBabyInput) {
    return await prisma.baby.create({
      data: {
        parentId,
        name: data.name,
        birthDate: new Date(data.dateOfBirth),
        gender: data.gender,
        bloodGroup: data.bloodGroup || null,
        birthWeight: data.birthWeight || null,
        birthHeight: data.birthHeight || null,
        photoUrl: data.photoUrl || null,
      },
    });
  }

  /**
   * List all non-deleted babies belonging to the parent or assigned to the caregiver.
   */
  public async listBabies(userId: string) {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
    if (!isUuid) {
      console.warn(`[BabyService] listBabies called with non-UUID userId: ${userId}`);
      return [];
    }

    const now = new Date();
    return await prisma.baby.findMany({
      where: {
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
          {
            temporaryCaregiverPermissions: {
              some: {
                caregiverId: userId,
                status: 'ACTIVE',
                revoked: false,
                expiresAt: { gt: now },
              },
            },
          },
        ],
        deletedAt: null,
      },
      include: {
        caregivers: {
          where: { userId },
          select: { accessLevel: true },
        },
        temporaryCaregiverPermissions: {
          where: {
            caregiverId: userId,
            status: 'ACTIVE',
            revoked: false,
            expiresAt: { gt: now },
          },
          select: { permission: true, expiresAt: true },
        },
      },

      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  /**
   * Get baby details by ID. Verifies parent or caregiver ownership/access.
   */
  public async getBabyById(babyId: string, userId: string) {
    const now = new Date();
    const baby = await prisma.baby.findFirst({
      where: {
        id: babyId,
        deletedAt: null,
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
          {
            temporaryCaregiverPermissions: {
              some: {
                caregiverId: userId,
                revoked: false,
                expiresAt: { gt: now },
              },
            },
          },
        ],
      },
      include: {
        caregivers: {
          where: { userId },
          select: { accessLevel: true },
        },
        temporaryCaregiverPermissions: {
          where: {
            caregiverId: userId,
            revoked: false,
            expiresAt: { gt: now },
          },
          select: { permission: true, expiresAt: true },
        },
      },
    });

    if (!baby) {
      const exists = await prisma.baby.findFirst({
        where: { id: babyId },
        include: {
          caregivers: {
            where: { userId },
          }
        }
      });

      if (exists) {
        if (exists.deletedAt !== null) {
          const error: any = new Error('Baby profile has been deleted.');
          error.statusCode = 404;
          throw error;
        }
        // If it is not deleted but they don't have access
        const error: any = new Error('Access denied to baby profile.');
        error.statusCode = 403;
        throw error;
      }

      const error: any = new Error('Baby profile not found.');
      error.statusCode = 404;
      throw error;
    }

    return baby;
  }

  /**
   * Update baby profile. Verifies parent ownership.
   */
  public async updateBaby(babyId: string, parentId: string, data: UpdateBabyInput) {
    // Verify ownership and existence first
    const baby = await this.getBabyById(babyId, parentId);

    return await prisma.baby.update({
      where: { id: baby.id },
      data: {
        name: data.name ?? undefined,
        gender: data.gender ?? undefined,
        birthDate: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
        bloodGroup: data.bloodGroup !== undefined ? data.bloodGroup : undefined,
        birthWeight: data.birthWeight !== undefined ? data.birthWeight : undefined,
        birthHeight: data.birthHeight !== undefined ? data.birthHeight : undefined,
        photoUrl: data.photoUrl !== undefined ? data.photoUrl : undefined,
      },
    });
  }

  /**
   * Soft delete a baby profile. Verifies parent ownership.
   */
  public async deleteBaby(babyId: string, parentId: string) {
    // Verify ownership and existence first
    const baby = await this.getBabyById(babyId, parentId);

    return await prisma.baby.update({
      where: { id: baby.id },
      data: {
        deletedAt: new Date(),
      },
    });
  }
}
