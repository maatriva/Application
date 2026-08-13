import crypto from 'crypto';
import { prisma } from '../../config/database';
import { WebsocketServerManager } from '../../websocket/websocketServer';

export class CaregiversService {
  /**
   * Invite a caregiver via Email/Role (Legacy Invitation).
   */
  public async inviteCaregiver(data: {
    babyId: string;
    email: string;
    role: string;
    parentId: string;
    expiresInHours?: number;
    expiresInMinutes?: number;
  }) {
    const baby = await prisma.baby.findUnique({
      where: { id: data.babyId },
    });

    if (!baby) {
      throw { statusCode: 404, message: 'Baby profile not found.' };
    }

    if (baby.parentId !== data.parentId) {
      throw { statusCode: 403, message: 'Access denied: Only primary parents can invite caregivers.' };
    }

    const token = crypto.randomBytes(32).toString('hex');
    const minutes = data.expiresInMinutes || (data.expiresInHours ? data.expiresInHours * 60 : 60);
    const expiresAt = new Date(Date.now() + minutes * 60 * 1000);

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

    await prisma.auditLog.create({
      data: {
        userId: data.parentId,
        action: 'INVITATION_CREATED',
        targetTable: 'invitations',
        targetId: invitation.id,
        details: `Invited caregiver ${data.email} as ${data.role} for baby ${baby.name}`,
      },
    });

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
   * Accept an invitation using secure token or QR invitation token.
   */
  public async acceptInvitation(token: string, userId: string) {
    // 1. Verify user profile exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 401, message: 'Please log in to your MAATRIVA caregiver account before accepting this invitation.' };
    }

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // 2. Check TemporaryCaregiverPermission QR invitations first
    const tempRecord = await (prisma as any).temporaryCaregiverPermission.findFirst({
      where: {
        OR: [
          { invitationToken: token },
          { invitationTokenHash: tokenHash },
        ],
      },
      include: { baby: true },
    });

    if (tempRecord) {
      if (tempRecord.status === 'REVOKED' || tempRecord.revoked) {
        throw { statusCode: 400, message: 'This caregiver invitation has been revoked by the parent.' };
      }

      if (tempRecord.status !== 'PENDING') {
        throw { statusCode: 400, message: 'This QR code invitation has already been used by another caregiver.' };
      }

      const now = new Date();
      if (tempRecord.invitationExpiresAt && now > tempRecord.invitationExpiresAt) {
        await (prisma as any).temporaryCaregiverPermission.update({
          where: { id: tempRecord.id },
          data: { status: 'EXPIRED' },
        });
        throw { statusCode: 400, message: 'QR Code has expired. Please ask the parent for a new QR code.' };
      }

      // The acceptance transition must be atomic. The server's transaction time is
      // the authoritative start time; invitation expiry never shortens access time.
      const updated = await (prisma as any).$transaction(async (tx: any) => {
        const invitation = await tx.temporaryCaregiverPermission.findUnique({
          where: { id: tempRecord.id }, include: { baby: true },
        });
        const acceptedAt = new Date();
        if (!invitation || invitation.status !== 'PENDING' || invitation.revoked) {
          throw { statusCode: 400, message: 'Invitation already used or revoked.' };
        }
        if (invitation.invitationExpiresAt && acceptedAt >= invitation.invitationExpiresAt) {
          await tx.temporaryCaregiverPermission.update({ where: { id: tempRecord.id }, data: { status: 'EXPIRED' } });
          throw { statusCode: 400, message: 'QR Code has expired. Please ask the parent for a new QR code.' };
        }
        const conflicting = await tx.temporaryCaregiverPermission.findFirst({
          where: { babyId: invitation.babyId, status: 'ACTIVE', revoked: false, expiresAt: { gt: acceptedAt } },
        });
        if (conflicting) throw { statusCode: 409, message: 'An active caregiver already has access.' };
        const expiresAt = new Date(acceptedAt.getTime() + invitation.durationMinutes * 60000);
        const access = await tx.temporaryCaregiverPermission.update({
          where: { id: invitation.id },
          data: { caregiverId: userId, status: 'ACTIVE', grantedAt: acceptedAt, acceptedAt, lastActiveAt: acceptedAt, expiresAt },
          include: { baby: { select: { id: true, name: true, gender: true, birthDate: true, photoUrl: true } }, caregiver: { select: { fullName: true, email: true } } },
        });
        await tx.caregiver.upsert({
          where: { babyId_userId: { babyId: invitation.babyId, userId } },
          update: { accessLevel: invitation.permission || 'LIVE_MONITOR_ONLY', status: 'accepted' },
          create: { babyId: invitation.babyId, userId, accessLevel: invitation.permission || 'LIVE_MONITOR_ONLY', status: 'accepted', invitedBy: invitation.parentId },
        });
        return access;
      }, { isolationLevel: 'Serializable' });

      // Audit Log
      await prisma.auditLog.create({
        data: {
          userId,
          action: 'QR_INVITATION_ACCEPTED',
          targetTable: 'temporary_caregiver_permissions',
          targetId: tempRecord.id,
          details: `Caregiver ${user.email} accepted QR invitation for baby ${tempRecord.baby.name}`,
        },
      });

      // Real-Time Socket.IO Push Event
      try {
        const payload = {
          accessId: updated.id,
          permissionId: updated.id,
          babyId: tempRecord.babyId,
          babyName: tempRecord.baby.name,
          caregiverId: userId,
          caregiverName: updated.caregiver?.fullName || updated.caregiver?.email || 'Caregiver',
          status: 'ACTIVE',
          startedAt: updated.acceptedAt.toISOString(),
          expiresAt: updated.expiresAt.toISOString(),
          permissions: updated.permissions,
          baby: updated.baby,
        };
        WebsocketServerManager.getInstance().emitToUser(tempRecord.parentId, 'caregiver.access.accepted', payload);
        WebsocketServerManager.getInstance().emitToUser(userId, 'caregiver:access_granted', payload);
        WebsocketServerManager.getInstance().emitToUser(userId, 'caregiver_access_granted', payload);
      } catch (_) {}

      return {
        message: 'Caregiver invitation accepted successfully.',
        caregiverAccess: updated,
      };
    }

    // 3. Fallback: Check standard email Invitation model
    const invitation = await prisma.invitation.findUnique({
      where: { token },
      include: { baby: true },
    });

    if (!invitation) {
      throw { statusCode: 404, message: 'Invalid or expired QR code invitation.' };
    }

    if (invitation.status !== 'PENDING') {
      throw { statusCode: 400, message: 'QR Code invitation has already been used.' };
    }

    if (new Date() > invitation.expiresAt) {
      await prisma.invitation.update({
        where: { id: invitation.id },
        data: { status: 'EXPIRED' },
      });
      throw { statusCode: 400, message: 'QR Code has expired. Please ask the parent for a new QR code.' };
    }

    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'ACCEPTED' },
    });

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

    await prisma.auditLog.create({
      data: {
        userId,
        action: 'INVITATION_ACCEPTED',
        targetTable: 'caregivers',
        targetId: caregiver.id,
        details: `Caregiver ${user.email} accepted invitation for baby ${invitation.baby.name} as ${invitation.role}`,
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

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User profile not found.' };
    }

    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'REJECTED' },
    });

    await prisma.auditLog.create({
      data: {
        userId,
        action: 'INVITATION_REJECTED',
        targetTable: 'invitations',
        targetId: invitation.id,
        details: `Caregiver ${user.email} rejected invitation for baby ${invitation.baby.name}`,
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

      const temporaryPermissions = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: {
        babyId,
        status: { in: ['PENDING', 'ACTIVE'] },
        revoked: false,
        OR: [
          { status: 'PENDING', invitationExpiresAt: { gt: new Date() } },
          { status: 'ACTIVE', expiresAt: { gt: new Date() } },
        ],
      },
      include: {
        caregiver: { select: { id: true, fullName: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
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
      temporaryPermissions: temporaryPermissions.map((tp: any) => ({
        id: tp.id,
        caregiverId: tp.caregiverId,
        caregiverName: tp.caregiver?.fullName || 'Guest Caregiver',
        caregiverEmail: tp.caregiver?.email || '',
        status: tp.status,
        durationMinutes: tp.durationMinutes,
        grantedAt: tp.grantedAt?.toISOString() || tp.createdAt.toISOString(),
        expiresAt: tp.expiresAt.toISOString(),
        invitationExpiresAt: tp.invitationExpiresAt?.toISOString(),
        permissions: tp.permissions,
        canViewCamera: tp.canViewCamera,
        canViewLiveMonitoring: tp.canViewLiveMonitoring,
        canReceiveAlerts: tp.canReceiveAlerts,
        canViewTelemetry: tp.canViewTelemetry,
      })),
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

    if (record.baby.parentId !== requesterId) {
      throw { statusCode: 403, message: 'Access denied: Only primary parents can manage caregiver roles.' };
    }

    const updated = await prisma.caregiver.update({
      where: { id: mappingId },
      data: {
        ...(data.role && { accessLevel: data.role.toUpperCase() }),
        ...(data.status && { status: data.status.toLowerCase() }),
      },
      include: { user: { select: { email: true, fullName: true } } },
    });

    await prisma.auditLog.create({
      data: {
        userId: requesterId,
        action: 'CAREGIVER_ROLE_UPDATED',
        targetTable: 'caregivers',
        targetId: mappingId,
        details: `Updated caregiver ${record.user.email} (Role: ${data.role || record.accessLevel}, Status: ${data.status || record.status})`,
      },
    });

    return updated;
  }

  /**
   * Revoke base caregiver access mapping.
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
      throw { statusCode: 403, message: 'Access denied: Only parent or caregiver can revoke access.' };
    }

    await prisma.caregiver.delete({
      where: { id: mappingId },
    });

    // Revoke any matching temporary permission records
    try {
      await (prisma as any).temporaryCaregiverPermission.updateMany({
        where: {
          babyId: record.babyId,
          caregiverId: record.userId,
        },
        data: {
          status: 'REVOKED',
          revoked: true,
          revokedAt: new Date(),
          revokedBy: requesterId,
        },
      });
    } catch (_) {}

    try {
      const payload = {
        babyId: record.babyId,
        reason: 'PARENT_REVOKED',
        message: `Your caregiver monitoring access for baby ${record.baby.name} has been revoked by the parent.`,
      };
      WebsocketServerManager.getInstance().emitToUser(record.userId, 'caregiver_access_revoked', payload);
      WebsocketServerManager.getInstance().emitToUser(record.userId, 'caregiver:access_revoked', payload);
    } catch (wsErr) {
      console.error('[CaregiversService] Error broadcasting socket revocation event:', wsErr);
    }

    await prisma.auditLog.create({
      data: {
        userId: requesterId,
        action: 'CAREGIVER_REMOVED',
        targetTable: 'caregivers',
        targetId: mappingId,
        details: `Revoked access mapping for caregiver ${record.user.email} from baby ${record.baby.name}`,
      },
    });

    return { message: 'Caregiver access revoked successfully.' };
  }

  /**
   * List pending invitations.
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

  /**
   * Generate QR Invitation / Grant Temporary Access (Parent Flow).
   * Generates secure 256-bit invitation token. No JWT, password, or sensitive baby info inside QR.
   */
  public async grantTemporaryAccess(data: {
    parentId: string;
    caregiverEmail?: string;
    babyId: string;
    durationMinutes: number;
    permission?: string;
    permissions?: Record<string, boolean>;
  }) {
    const baby = await prisma.baby.findUnique({
      where: { id: data.babyId },
    });

    if (!baby) {
      throw { statusCode: 404, message: 'Baby profile not found.' };
    }

    if (baby.parentId !== data.parentId) {
      throw { statusCode: 403, message: 'Access denied: Only primary parents can grant temporary caregiver access.' };
    }

    let caregiverUserId: string | null = null;
    if (data.caregiverEmail) {
      const caregiverUser = await prisma.user.findUnique({
        where: { email: data.caregiverEmail.toLowerCase() },
      });
      if (caregiverUser) {
        caregiverUserId = caregiverUser.id;
      }
    }

    const minutes = Number(data.durationMinutes);
    if (!Number.isInteger(minutes) || minutes < 1 || minutes > 10080) {
      throw { statusCode: 400, message: 'durationMinutes must be between 1 minute and 7 days.' };
    }
    const now = new Date();
    // This is only a placeholder while the invitation is waiting. The actual
    // access expiry is computed from acceptedAt + durationMinutes at acceptance.
    const expiresAt = now;
    const invitationExpiresAt = new Date(now.getTime() + 10 * 60 * 1000); // QR invitation scannable for 10 minutes
    const permType = data.permission || 'LIVE_MONITOR_ONLY';

    // Generate secure random invitation token & hash
    const invitationToken = crypto.randomBytes(32).toString('hex');
    const invitationTokenHash = crypto.createHash('sha256').update(invitationToken).digest('hex');

    const permsObj = data.permissions || {
      live_monitoring: true,
      camera_snapshot: false,
      emergency_alerts: false,
      health_data: false,
      custom_music: false,
      music: false,
      ai_assistant: false,
      cradle_controls: false,
    };

    const active = await (prisma as any).temporaryCaregiverPermission.findFirst({
      where: { parentId: data.parentId, babyId: data.babyId, status: 'ACTIVE', revoked: false, expiresAt: { gt: now } },
    });
    if (active) throw { statusCode: 409, message: 'An active caregiver already has access.' };

    // Replace stale pending invitations only; never invalidate an active access.
    try {
      await (prisma as any).temporaryCaregiverPermission.updateMany({
        where: {
          parentId: data.parentId,
          babyId: data.babyId,
          status: 'PENDING',
        },
        data: {
          status: 'EXPIRED',
          revoked: true,
          revokedAt: now,
        },
      });
    } catch (_) {}

    // Create temporary caregiver permission record
    const tempPermission = await (prisma as any).temporaryCaregiverPermission.create({
      data: {
        parentId: data.parentId,
        caregiverId: caregiverUserId,
        babyId: data.babyId,
        invitationToken,
        invitationTokenHash,
        invitationExpiresAt,
        permission: permType,
        permissions: permsObj,
        durationMinutes: minutes,
        grantedAt: now,
        expiresAt,
        status: 'PENDING',
        revoked: false,
        canViewLiveMonitoring: permsObj.live_monitoring ?? true,
        canViewCamera: permsObj.camera_snapshot ?? false,
        canReceiveAlerts: permsObj.emergency_alerts ?? false,
        canViewTelemetry: permsObj.health_data ?? false,
        canViewCustomLullabies: permsObj.custom_music ?? false,
        canPlayMusic: permsObj.music ?? false,
        canControlCradle: permsObj.cradle_controls ?? false,
        canViewHealthHistory: permsObj.health_data ?? false,
        canUseAI: permsObj.ai_assistant ?? false,
      },
      include: {
        baby: { select: { id: true, name: true, gender: true, birthDate: true, photoUrl: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: data.parentId,
        action: 'QR_INVITATION_GENERATED',
        targetTable: 'temporary_caregiver_permissions',
        targetId: tempPermission.id,
        details: `Parent generated ${minutes} min caregiver QR invitation for baby ${baby.name}`,
      },
    });

    return {
      permissionId: tempPermission.id,
      invitationToken,
      babyId: data.babyId,
      grantedAt: tempPermission.grantedAt,
      durationMinutes: tempPermission.durationMinutes,
      expiresAt: null,
      invitationExpiresAt: tempPermission.invitationExpiresAt,
      status: tempPermission.status,
      permissions: tempPermission.permissions,
    };
  }

  /**
   * Fetch active, non-expired, non-revoked caregiver access permissions (Requirement 4 & Re-login Restoration).
   */
  public async getActivePermissions(caregiverId: string) {
    const now = new Date();
    const permissions = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: {
        caregiverId,
        status: 'ACTIVE',
        revoked: false,
        expiresAt: { gt: now },
        revokedAt: null,
      },
      include: {
        baby: { select: { id: true, name: true, birthDate: true, gender: true, photoUrl: true } },
        parent: { select: { id: true, fullName: true, email: true } },
      },
      orderBy: { expiresAt: 'desc' },
    });

    if (permissions.length > 0) {
      // Filter out any anomalous old test records where duration was set > 48 hours
      const validPermissions = permissions.filter((p: any) => {
        const grantedTime = (p.grantedAt || p.createdAt).getTime();
        const durationHours = (p.expiresAt.getTime() - grantedTime) / (1000 * 3600);
        return durationHours <= 48;
      });

      if (validPermissions.length > 0) {
        // Update lastActiveAt
        try {
          await (prisma as any).temporaryCaregiverPermission.updateMany({
            where: {
              id: { in: validPermissions.map((p: any) => p.id) },
            },
            data: { lastActiveAt: now },
          });
        } catch (_) {}

        return validPermissions.map((p: any) => ({
        id: p.id,
        parentId: p.parentId,
        caregiverId: p.caregiverId,
        babyId: p.babyId,
        permission: p.permission,
        permissions: p.permissions || {
          live_monitoring: p.canViewLiveMonitoring,
          camera_snapshot: p.canViewCamera,
          emergency_alerts: p.canReceiveAlerts,
          health_data: p.canViewTelemetry,
          custom_music: p.canViewCustomLullabies,
          music: p.canPlayMusic,
          ai_assistant: p.canUseAI,
          cradle_controls: p.canControlCradle,
        },
        canViewLiveMonitoring: p.canViewLiveMonitoring,
        canViewCamera: p.canViewCamera,
        canReceiveAlerts: p.canReceiveAlerts,
        canViewTelemetry: p.canViewTelemetry,
        canViewCustomLullabies: p.canViewCustomLullabies,
        canPlayMusic: p.canPlayMusic,
        canControlCradle: p.canControlCradle,
        canViewHealthHistory: p.canViewHealthHistory,
        canUseAI: p.canUseAI,
        expiresAt: p.expiresAt.toISOString(),
        grantedAt: p.grantedAt?.toISOString(),
        acceptedAt: p.acceptedAt?.toISOString(),
        status: p.status,
        revoked: p.revoked,
        createdAt: p.createdAt.toISOString(),
        babyName: p.baby?.name || 'Shared Baby',
        parentName: p.parent?.fullName || 'Parent',
        baby: p.baby,
      }));
      }
    }

    // Do NOT fall back to 365-day baseCaregivers if caregiver was granted access via temporary QR permissions
    const hasTempRecord = await (prisma as any).temporaryCaregiverPermission.findFirst({
      where: { caregiverId },
    });

    if (!hasTempRecord) {
      const baseCaregivers = await prisma.caregiver.findMany({
        where: {
          userId: caregiverId,
          status: 'accepted',
          accessLevel: { in: ['SECONDARY_PARENT', 'CO_PARENT', 'PERMANENT_CAREGIVER'] },
        },
        include: {
          baby: {
            select: {
              id: true,
              name: true,
              birthDate: true,
              gender: true,
              photoUrl: true,
              parent: { select: { id: true, fullName: true, email: true } },
            },
          },
        },
      });

      if (baseCaregivers.length > 0) {
        const farFuture = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString();
        return baseCaregivers.map((c) => ({
          id: c.id,
          parentId: c.invitedBy || c.baby.parent?.id || '',
          caregiverId: c.userId,
          babyId: c.babyId,
          permission: c.accessLevel || 'LIVE_MONITOR_ONLY',
          permissions: {
            live_monitoring: true,
            camera_snapshot: true,
            emergency_alerts: true,
            health_data: true,
            custom_music: false,
            music: true,
            ai_assistant: false,
            cradle_controls: false,
          },
          canViewLiveMonitoring: true,
          canViewCamera: true,
          canReceiveAlerts: true,
          canViewTelemetry: true,
          expiresAt: farFuture,
          status: 'ACTIVE',
          revoked: false,
          createdAt: c.createdAt.toISOString(),
          babyName: c.baby?.name || 'Shared Baby',
          parentName: c.baby?.parent?.fullName || 'Parent',
          baby: c.baby,
        }));
      }
    }

    return [];
  }

  /**
   * Helper to check permission status.
   */
  public async checkCaregiverPermissionStatus(caregiverId: string): Promise<{ revoked: boolean; expired: boolean }> {
    const records = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: { caregiverId },
      orderBy: { createdAt: 'desc' },
      take: 1,
    });
    if (records.length === 0) {
      return { revoked: false, expired: false };
    }
    const latest = records[0];
    if (latest.status === 'REVOKED' || latest.revoked) {
      return { revoked: true, expired: false };
    }
    if (new Date() > new Date(latest.expiresAt)) {
      return { revoked: false, expired: true };
    }
    return { revoked: false, expired: false };
  }

  /**
   * Edit feature-level permissions for active caregiver access.
   */
  public async updateTemporaryPermissions(permissionId: string, parentId: string, permissions: Record<string, boolean>) {
    let record = await (prisma as any).temporaryCaregiverPermission.findUnique({
      where: { id: permissionId },
      include: { baby: true, caregiver: true },
    });

    if (!record) {
      throw { statusCode: 404, message: 'Caregiver access record not found.' };
    }

    if (record.parentId !== parentId && record.baby?.parentId !== parentId) {
      throw { statusCode: 403, message: 'Access denied: Only the parent can update permissions.' };
    }

    const updated = await (prisma as any).temporaryCaregiverPermission.update({
      where: { id: record.id },
      data: {
        permissions,
        canViewLiveMonitoring: permissions.live_monitoring ?? record.canViewLiveMonitoring,
        canViewCamera: permissions.camera_snapshot ?? record.canViewCamera,
        canReceiveAlerts: permissions.emergency_alerts ?? record.canReceiveAlerts,
        canViewTelemetry: permissions.health_data ?? record.canViewTelemetry,
        canViewCustomLullabies: permissions.custom_music ?? record.canViewCustomLullabies,
        canPlayMusic: permissions.music ?? record.canPlayMusic,
        canControlCradle: permissions.cradle_controls ?? record.canControlCradle,
        canViewHealthHistory: permissions.health_data ?? record.canViewHealthHistory,
        canUseAI: permissions.ai_assistant ?? record.canUseAI,
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: parentId,
        action: 'CAREGIVER_PERMISSIONS_UPDATED',
        targetTable: 'temporary_caregiver_permissions',
        targetId: record.id,
        details: `Parent updated permissions for caregiver access ${record.id}`,
      },
    });

    // Notify caregiver immediately via Socket.IO
    if (record.caregiverId) {
      try {
        const payload = {
          permissionId: record.id,
          babyId: record.babyId,
          permissions,
        };
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver_permissions_updated', payload);
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver:permissions_updated', payload);
        WebsocketServerManager.getInstance().emitToUser(record.parentId, 'caregiver.permission.updated', payload);
      } catch (wsErr) {
        console.error('[CaregiversService] Error emitting permissions updated event:', wsErr);
      }
    }

    return updated;
  }

  /**
   * Extend caregiver access duration (+15m, +30m, +1h, custom).
   */
  public async extendTemporaryAccess(permissionId: string, parentId: string, extensionMinutes: number) {
    let record = await (prisma as any).temporaryCaregiverPermission.findUnique({
      where: { id: permissionId },
      include: { baby: true, caregiver: true },
    });

    if (!record) {
      throw { statusCode: 404, message: 'Caregiver access record not found.' };
    }

    if (record.parentId !== parentId && record.baby?.parentId !== parentId) {
      throw { statusCode: 403, message: 'Access denied: Only the parent can extend access.' };
    }

    const baseTime = record.expiresAt > new Date() ? record.expiresAt.getTime() : Date.now();
    const newExpiresAt = new Date(baseTime + Math.max(1, extensionMinutes) * 60 * 1000);

    const updated = await (prisma as any).temporaryCaregiverPermission.update({
      where: { id: record.id },
      data: {
        expiresAt: newExpiresAt,
        status: 'ACTIVE',
        revoked: false,
        revokedAt: null,
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: parentId,
        action: 'CAREGIVER_ACCESS_EXTENDED',
        targetTable: 'temporary_caregiver_permissions',
        targetId: record.id,
        details: `Extended caregiver access by ${extensionMinutes} minutes until ${newExpiresAt.toISOString()}`,
      },
    });

    if (record.caregiverId) {
      try {
        const payload = {
          permissionId: record.id,
          babyId: record.babyId,
          expiresAt: newExpiresAt.toISOString(),
        };
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver_access_extended', payload);
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver:access_extended', payload);
        WebsocketServerManager.getInstance().emitToUser(record.parentId, 'caregiver.access.extended', payload);
      } catch (wsErr) {
        console.error('[CaregiversService] Error emitting access extended event:', wsErr);
      }
    }

    return updated;
  }

  /**
   * Revoke temporary access immediately (Requirement 6 & Force Logout).
   */
  public async revokeTemporaryPermission(permissionId: string, requesterId: string) {
    let record = await (prisma as any).temporaryCaregiverPermission.findUnique({
      where: { id: permissionId },
      include: { baby: true, caregiver: true },
    });

    if (!record) {
      const caregiverMapping = await prisma.caregiver.findUnique({
        where: { id: permissionId },
        include: { baby: true, user: true },
      });

      if (caregiverMapping) {
        await prisma.caregiver.delete({
          where: { id: permissionId },
        });
        try {
          const payload = {
            babyId: caregiverMapping.babyId,
            reason: 'PARENT_REVOKED',
            message: `Your caregiver access for baby ${caregiverMapping.baby?.name || 'baby'} has been removed by the parent.`,
          };
          WebsocketServerManager.getInstance().emitToUser(caregiverMapping.userId, 'caregiver_access_revoked', payload);
          WebsocketServerManager.getInstance().emitToUser(caregiverMapping.userId, 'caregiver:access_revoked', payload);
        } catch (_) {}
        return { success: true, message: 'Caregiver access revoked successfully.' };
      }
    }

    if (!record) {
      throw { statusCode: 404, message: 'Caregiver access record not found.' };
    }

    if (requesterId !== record.parentId && requesterId !== record.caregiverId && record.baby?.parentId !== requesterId) {
      throw { statusCode: 403, message: 'Access denied: Only parent or caregiver can revoke permission.' };
    }

    const now = new Date();
    const updated = await (prisma as any).temporaryCaregiverPermission.update({
      where: { id: record.id },
      data: {
        status: 'REVOKED',
        revoked: true,
        revokedAt: now,
        revokedBy: requesterId,
      },
    });

    if (record.caregiverId) {
      try {
        await prisma.caregiver.deleteMany({
          where: {
            babyId: record.babyId,
            userId: record.caregiverId,
          },
        });
      } catch (_) {}

      try {
        const payload = {
          permissionId: record.id,
          babyId: record.babyId,
          reason: 'PARENT_REVOKED',
          message: `Your caregiver access for baby ${record.baby?.name || 'baby'} has been removed by the parent.`,
        };
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver_access_revoked', payload);
        WebsocketServerManager.getInstance().emitToUser(record.caregiverId, 'caregiver:access_revoked', payload);
        WebsocketServerManager.getInstance().emitToUser(record.parentId, 'caregiver.access.revoked', payload);
      } catch (wsErr) {
        console.error('[CaregiversService] Error emitting real-time revocation event:', wsErr);
      }
    }

    await prisma.auditLog.create({
      data: {
        userId: requesterId,
        action: 'CAREGIVER_ACCESS_REVOKED',
        targetTable: 'temporary_caregiver_permissions',
        targetId: permissionId,
        details: `Revoked caregiver access for baby ${record.baby?.name}`,
      },
    });

    return { success: true, message: 'Caregiver access revoked successfully.', record: updated };
  }

  /**
   * Helper to verify if caregiver holds a valid permission.
   */
  public async verifyCaregiverPermission(caregiverId: string, babyId?: string): Promise<boolean> {
    const now = new Date();
    const whereClause: any = {
      caregiverId,
      status: 'ACTIVE',
      revoked: false,
      expiresAt: { gt: now },
      revokedAt: null,
    };
    if (babyId) {
      whereClause.babyId = babyId;
    }

    const count = await (prisma as any).temporaryCaregiverPermission.count({
      where: whereClause,
    });
    return count > 0;
  }

  /**
   * Fetch persisted access history for a baby profile.
   */
  public async getAccessHistory(babyId: string) {
    const records = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: { babyId },
      include: {
        caregiver: { select: { id: true, fullName: true, email: true } },
        parent: { select: { id: true, fullName: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const now = new Date();

    return records.map((rec: any) => {
      const isRevoked = rec.status === 'REVOKED' || rec.revoked;
      const isExpired = rec.expiresAt < now || rec.status === 'EXPIRED';
      const isActive = rec.status === 'ACTIVE' && !isRevoked && !isExpired;

      let status = 'Completed';
      if (isRevoked) {
        status = 'Revoked';
      } else if (isExpired) {
        status = 'Expired';
      } else if (isActive) {
        status = 'Active';
      }

      const startTime = rec.acceptedAt || rec.grantedAt || rec.createdAt;
      const endTime = rec.revokedAt || rec.expiresAt;

      const durationMs = (endTime.getTime() - startTime.getTime());
      const durationMins = Math.max(1, Math.round(durationMs / (1000 * 60)));
      let durationText = `${durationMins} mins`;
      if (durationMins >= 60) {
        const hrs = (durationMins / 60).toFixed(1).replace('.0', '');
        durationText = `${hrs} ${Number(hrs) === 1 ? 'hour' : 'hours'}`;
      }

      return {
        id: rec.id,
        name: rec.caregiver?.fullName || rec.caregiver?.email || 'Caregiver Guest',
        relationship: rec.permission === 'LIVE_MONITOR_ONLY' ? 'Temporary Caregiver' : 'Family Caregiver',
        grantedAt: rec.grantedAt?.toISOString() || rec.createdAt.toISOString(),
        acceptedAt: rec.acceptedAt?.toISOString(),
        expiresAt: rec.expiresAt.toISOString(),
        revokedAt: rec.revokedAt?.toISOString(),
        status,
        durationText,
        permissions: rec.permissions,
      };
    });
  }
}
