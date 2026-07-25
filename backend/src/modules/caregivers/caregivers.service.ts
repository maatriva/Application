import crypto from 'crypto';
import { prisma } from '../../config/database';

export class CaregiversService {
  /**
   * Invite a caregiver. Only primary parent can invite.
   */
  public async inviteCaregiver(data: {
    babyId: string;
    email: string;
    role: string;
    parentId: string;
    expiresInHours?: number;
  }) {
    // 1. Verify that the baby profile exists
    const baby = await prisma.baby.findUnique({
      where: { id: data.babyId },
    });

    if (!baby) {
      throw { statusCode: 404, message: 'Baby profile not found.' };
    }

    // 2. Verify that the inviter is the primary parent of the baby
    if (baby.parentId !== data.parentId) {
      throw { statusCode: 403, message: 'Access denied: Only primary parents can invite caregivers.' };
    }

    // 3. Generate secure token & expiration
    const token = crypto.randomBytes(32).toString('hex');
    const hours = data.expiresInHours || 24;
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + hours);

    // 4. Create Invitation
    const invitation = await prisma.invitation.create({
      data: {
        babyId: data.babyId,
        email: data.email.toLowerCase(),
        role: data.role.toUpperCase(),
        token,
        status: 'PENDING',
        invitedBy: data.parentId,
        expiresAt,
      },
      include: {
        baby: { select: { name: true } },
      },
    });

    // 5. Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId: data.parentId,
        action: 'INVITATION_CREATED',
        targetTable: 'invitations',
        targetId: invitation.id,
        details: `Invited caregiver ${data.email} as ${data.role} for baby ${baby.name}`,
      },
    });

    // 6. Generate Parent Notification
    await prisma.notificationHistory.create({
      data: {
        userId: data.parentId,
        title: 'Invitation Sent',
        message: `An invitation has been generated for ${data.email} with role ${data.role}.`,
      },
    });

    return invitation;
  }

  /**
   * Accept an invitation using secure token.
   */
  public async acceptInvitation(token: string, userId: string) {
    // 1. Find invitation
    const invitation = await prisma.invitation.findUnique({
      where: { token },
      include: { baby: true },
    });

    if (!invitation) {
      throw { statusCode: 404, message: 'Invitation not found.' };
    }

    if (invitation.status !== 'PENDING') {
      throw { statusCode: 400, message: `Invitation cannot be accepted. Current status: ${invitation.status}` };
    }

    if (new Date() > invitation.expiresAt) {
      await prisma.invitation.update({
        where: { id: invitation.id },
        data: { status: 'EXPIRED' },
      });
      throw { statusCode: 400, message: 'Invitation has expired.' };
    }

    // 2. Fetch logged-in user profile to verify matching email (if email is defined in invite)
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User profile not found.' };
    }

    if (invitation.email && invitation.email !== '*' && invitation.email !== user.email.toLowerCase()) {
      throw { statusCode: 403, message: 'Access denied: Invitation belongs to another user email.' };
    }

    // 3. Update status to ACCEPTED
    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'ACCEPTED' },
    });

    // 4. Create/Upsert Caregiver mapping
    const caregiver = await prisma.caregiver.upsert({
      where: {
        babyId_userId: {
          babyId: invitation.babyId,
          userId: user.id,
        },
      },
      update: {
        accessLevel: invitation.role,
        status: 'accepted',
      },
      create: {
        babyId: invitation.babyId,
        userId: user.id,
        accessLevel: invitation.role,
        status: 'accepted',
        invitedBy: invitation.invitedBy,
      },
    });

    // 5. Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'INVITATION_ACCEPTED',
        targetTable: 'caregivers',
        targetId: caregiver.id,
        details: `Caregiver ${user.email} accepted invitation for baby ${invitation.baby.name} as ${invitation.role}`,
      },
    });

    // 6. Generate Notification for inviter (primary parent)
    await prisma.notificationHistory.create({
      data: {
        userId: invitation.invitedBy,
        title: 'Invitation Accepted',
        message: `${user.fullName} has accepted your caregiver invitation for ${invitation.baby.name}.`,
      },
    });

    return {
      message: 'Invitation accepted successfully.',
      caregiver,
    };
  }

  /**
   * Reject an invitation.
   */
  public async rejectInvitation(token: string, userId: string) {
    const invitation = await prisma.invitation.findUnique({
      where: { token },
      include: { baby: true },
    });

    if (!invitation) {
      throw { statusCode: 404, message: 'Invitation not found.' };
    }

    if (invitation.status !== 'PENDING') {
      throw { statusCode: 400, message: 'Invitation is not pending.' };
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User profile not found.' };
    }

    // Update status to REJECTED
    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'REJECTED' },
    });

    // Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'INVITATION_REJECTED',
        targetTable: 'invitations',
        targetId: invitation.id,
        details: `Caregiver ${user.email} rejected invitation for baby ${invitation.baby.name}`,
      },
    });

    // Notify inviter (parent)
    await prisma.notificationHistory.create({
      data: {
        userId: invitation.invitedBy,
        title: 'Invitation Rejected',
        message: `${user.fullName} rejected the caregiver invitation for ${invitation.baby.name}.`,
      },
    });

    return { message: 'Invitation rejected successfully.' };
  }

  /**
   * List caregivers and pending invitations for a baby.
   */
  public async listCaregivers(babyId: string) {
    const caregivers = await prisma.caregiver.findMany({
      where: { babyId },
      include: {
        user: {
          select: { id: true, email: true, fullName: true },
        },
      },
    });

    const invitations = await prisma.invitation.findMany({
      where: {
        babyId,
        status: 'PENDING',
        expiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
        expiresAt: true,
        createdAt: true,
      },
    });

    return {
      caregivers: caregivers.map((c) => ({
        id: c.id,
        userId: c.userId,
        fullName: c.user.fullName,
        email: c.user.email,
        accessLevel: c.accessLevel,
        status: c.status,
      })),
      invitations,
    };
  }

  /**
   * Update caregiver role or status. Only parent can perform this.
   */
  public async updateCaregiver(
    mappingId: string,
    data: { role?: string; status?: string },
    requesterId: string
  ) {
    const record = await prisma.caregiver.findUnique({
      where: { id: mappingId },
      include: { baby: true, user: true },
    });

    if (!record) {
      throw { statusCode: 404, message: 'Caregiver mapping not found.' };
    }

    // Verify requester is the primary parent
    if (record.baby.parentId !== requesterId) {
      throw { statusCode: 403, message: 'Access denied: Only primary parents can manage caregiver roles.' };
    }

    const updated = await prisma.caregiver.update({
      where: { id: mappingId },
      data: {
        ...(data.role && { accessLevel: data.role.toUpperCase() }),
        ...(data.status && { status: data.status.toLowerCase() }), // e.g. 'disabled' or 'accepted'
      },
      include: { user: { select: { email: true, fullName: true } } },
    });

    // Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId: requesterId,
        action: 'CAREGIVER_ROLE_UPDATED',
        targetTable: 'caregivers',
        targetId: mappingId,
        details: `Updated caregiver ${record.user.email} (Role: ${data.role || record.accessLevel}, Status: ${data.status || record.status})`,
      },
    });

    // Notify Caregiver
    await prisma.notificationHistory.create({
      data: {
        userId: record.userId,
        title: 'Access Role Changed',
        message: `Your access role for baby ${record.baby.name} has been updated to ${data.role || record.accessLevel}.`,
      },
    });

    return updated;
  }

  /**
   * Revoke caregiver access.
   */
  public async revokeAccess(mappingId: string, requesterId: string) {
    const record = await prisma.caregiver.findUnique({
      where: { id: mappingId },
      include: { baby: true, user: true },
    });

    if (!record) {
      throw { statusCode: 404, message: 'Caregiver mapping not found.' };
    }

    if (requesterId !== record.userId && requesterId !== record.baby.parentId) {
      throw { statusCode: 403, message: 'Access denied: Only parent or the caregiver can revoke access.' };
    }

    await prisma.caregiver.delete({
      where: { id: mappingId },
    });

    // Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId: requesterId,
        action: 'CAREGIVER_REMOVED',
        targetTable: 'caregivers',
        targetId: mappingId,
        details: `Revoked access mapping for caregiver ${record.user.email} from baby ${record.baby.name}`,
      },
    });

    // Notify caregiver if parent revoked it
    if (requesterId === record.baby.parentId) {
      await prisma.notificationHistory.create({
        data: {
          userId: record.userId,
          title: 'Access Revoked',
          message: `Your caregiver monitoring access for baby ${record.baby.name} has been revoked.`,
        },
      });
    }

    return { message: 'Caregiver access revoked successfully.' };
  }

  /**
   * List pending invitations received by the current user email.
   */
  public async listReceivedInvitations(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User not found.' };
    }

    return await prisma.invitation.findMany({
      where: {
        email: user.email.toLowerCase(),
        status: 'PENDING',
        expiresAt: { gt: new Date() },
      },
      include: {
        baby: { select: { name: true } },
        inviter: { select: { fullName: true, email: true } },
      },
    });
  }
}
