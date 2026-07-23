import { prisma } from '../../config/database';

export class CaregiversService {
  /**
   * Invite a caregiver. Only parent can invite.
   */
  public async inviteCaregiver(data: {
    babyId: string;
    caregiverEmail: string;
    accessLevel?: string;
    parentId: string;
  }) {
    // 1. Verify that the inviter is the primary parent of the baby
    const baby = await prisma.baby.findUnique({
      where: { id: data.babyId },
    });

    if (!baby) {
      throw new Error('Baby profile not found.');
    }

    if (baby.parentId !== data.parentId) {
      throw new Error('Only primary parents can invite caregivers.');
    }

    // 2. Resolve caregiver's user ID by email
    const targetUser = await prisma.user.findUnique({
      where: { email: data.caregiverEmail },
    });

    if (!targetUser) {
      throw new Error('Invited user email has not registered an account with Maatriva yet.');
    }

    // 3. Create caregiver record or update on conflict
    return await prisma.caregiver.upsert({
      where: {
        babyId_userId: {
          babyId: data.babyId,
          userId: targetUser.id,
        },
      },
      update: {
        accessLevel: data.accessLevel || 'monitor',
      },
      create: {
        babyId: data.babyId,
        userId: targetUser.id,
        accessLevel: data.accessLevel || 'monitor',
        status: 'pending',
        invitedBy: data.parentId,
      },
      select: {
        id: true,
        babyId: true,
        userId: true,
        accessLevel: true,
        status: true,
      },
    });
  }

  /**
   * Accept an invitation.
   */
  public async acceptInvitation(invitationId: string, userId: string) {
    const invite = await prisma.caregiver.findUnique({
      where: { id: invitationId },
    });

    if (!invite) {
      throw new Error('Invitation not found.');
    }

    if (invite.userId !== userId) {
      throw new Error('Access denied: invitation belongs to another user.');
    }

    return await prisma.caregiver.update({
      where: { id: invitationId },
      data: { status: 'accepted' },
      select: {
        id: true,
        babyId: true,
        userId: true,
        accessLevel: true,
        status: true,
      },
    });
  }

  /**
   * List caregivers mapped to a baby.
   */
  public async listCaregivers(babyId: string) {
    const mappings = await prisma.caregiver.findMany({
      where: { babyId },
      select: {
        id: true,
        accessLevel: true,
        status: true,
        user: {
          select: {
            id: true,
            email: true,
            fullName: true,
          },
        },
      },
    });

    // Format output to match old API layout
    return mappings.map((m) => ({
      invitationId: m.id,
      accessLevel: m.accessLevel,
      status: m.status,
      userId: m.user.id,
      email: m.user.email,
      fullName: m.user.fullName,
    }));
  }

  /**
   * Revoke caregiver access.
   */
  public async revokeAccess(mappingId: string, requesterId: string) {
    const record = await prisma.caregiver.findUnique({
      where: { id: mappingId },
      include: {
        baby: true,
      },
    });

    if (!record) {
      throw new Error('Mapping not found.');
    }

    if (requesterId !== record.userId && requesterId !== record.baby.parentId) {
      throw new Error('Access denied: only parent or caregiver can revoke permissions.');
    }

    await prisma.caregiver.delete({
      where: { id: mappingId },
    });

    return { message: 'Caregiver access revoked successfully.' };
  }
}
