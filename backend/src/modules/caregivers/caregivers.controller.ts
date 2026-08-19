import { Response } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { CaregiversService } from './caregivers.service';

const caregiversService = new CaregiversService();

export class CaregiversController {
  /**
   * GET /caregivers/server-time
   * Provides a server reference time for display-only countdown synchronization.
   * Authorization decisions remain server-side in the protected endpoints.
   */
  public static async serverTime(_req: AuthenticatedRequest, res: Response) {
    res.json({ success: true, data: { serverTime: new Date().toISOString() } });
  }

  /**
   * POST /caregivers/invite
   */
  public static async invite(req: AuthenticatedRequest, res: Response) {
    const { babyId, email, role, expiresInHours } = req.body;
    const parentId = req.user?.userId;

    if (!parentId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!babyId || !email || !role) {
      return res.status(400).json({ error: 'babyId, email, and role are required.' });
    }

    try {
      const invitation = await caregiversService.inviteCaregiver({
        babyId,
        email,
        role,
        parentId,
        expiresInHours,
      });
      res.status(201).json({ success: true, data: invitation });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error creating invitation.' });
    }
  }

  /**
   * GET /caregivers
   */
  public static async list(req: AuthenticatedRequest, res: Response) {
    const babyId = req.query.babyId as string;
    const requesterId = req.user?.userId;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!babyId) {
      return res.status(400).json({ error: 'babyId query parameter is required.' });
    }

    try {
      const data = await caregiversService.listCaregivers(babyId, requesterId);
      res.json({ success: true, data });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ success: false, error: e.message || 'Error listing caregivers.' });
    }
  }

  /**
   * PATCH /caregivers/:id
   */
  public static async update(req: AuthenticatedRequest, res: Response) {
    const mappingId = req.params.id;
    const requesterId = req.user?.userId;
    const { role, status } = req.body;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const data = await caregiversService.updateCaregiver(mappingId, { role, status }, requesterId);
      res.json({ success: true, data });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error updating caregiver.' });
    }
  }

  /**
   * DELETE /caregivers/:id
   */
  public static async revoke(req: AuthenticatedRequest, res: Response) {
    const mappingId = req.params.id;
    const requesterId = req.user?.userId;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const result = await caregiversService.revokeAccess(mappingId, requesterId);
      res.json({ success: true, data: result });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error revoking caregiver access.' });
    }
  }

  /**
   * POST /caregivers/invitation/accept
   */
  public static async accept(req: AuthenticatedRequest, res: Response) {
    const { token } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!token) {
      return res.status(400).json({ error: 'token is required.' });
    }

    try {
      const result = await caregiversService.acceptInvitation(token, userId);
      res.json({ success: true, data: result });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error accepting invitation.' });
    }
  }

  /**
   * POST /caregivers/invitation/reject
   */
  public static async reject(req: AuthenticatedRequest, res: Response) {
    const { token } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!token) {
      return res.status(400).json({ error: 'token is required.' });
    }

    try {
      const result = await caregiversService.rejectInvitation(token, userId);
      res.json({ success: true, data: result });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error rejecting invitation.' });
    }
  }

  /**
   * GET /caregivers/invitations
   */
  public static async listInvitations(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const invitations = await caregiversService.listReceivedInvitations(userId);
      res.json({ success: true, data: invitations });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ success: false, error: e.message || 'Error listing received invitations.' });
    }
  }

  /**
   * POST /caregivers/grant-temporary
   */
  public static async grantTemporary(req: AuthenticatedRequest, res: Response) {
    const parentId = req.user?.userId;
    const { babyId, caregiverEmail, durationMinutes, permission } = req.body;

    if (!parentId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!babyId) {
      return res.status(400).json({ error: 'babyId is required.' });
    }

    try {
      const result = await caregiversService.grantTemporaryAccess({
        parentId,
        babyId,
        caregiverEmail,
        durationMinutes: Number(durationMinutes) || 60,
        permission,
        permissions: req.body.permissions,
      });
      res.status(201).json({ success: true, data: result });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error granting temporary caregiver access.' });
    }
  }

  /**
   * GET /caregivers/active-permissions
   */
  public static async getActivePermissions(req: AuthenticatedRequest, res: Response) {
    const caregiverId = req.user?.userId;

    if (!caregiverId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const permissions = await caregiversService.getActivePermissions(caregiverId);
      res.json({ success: true, data: permissions });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ success: false, error: e.message || 'Error fetching active permissions.' });
    }
  }

  /**
   * DELETE /caregivers/temporary-permission/:id
   */
  public static async revokeTemporaryPermission(req: AuthenticatedRequest, res: Response) {
    const permissionId = req.params.id;
    const requesterId = req.user?.userId;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const result = await caregiversService.revokeTemporaryPermission(permissionId, requesterId);
      res.json({ success: true, data: result });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error revoking temporary permission.' });
    }
  }

  /**
   * PATCH /caregivers/temporary-permission/:id/permissions
   * Parent edits feature-level permissions for caregiver
   */
  public static async updatePermissions(req: AuthenticatedRequest, res: Response) {
    const permissionId = req.params.id || req.body.permissionId || req.body.sessionId || req.body.caregiverId || '';
    const parentId = req.user?.userId;

    if (!parentId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    let permissions = req.body.permissions;
    if (!permissions || typeof permissions !== 'object') {
      permissions = {
        health_data: req.body.health_data ?? req.body.canViewTelemetry ?? true,
        ai_assistant: req.body.ai_assistant ?? req.body.canUseAi ?? true,
        emergency_alerts: req.body.emergency_alerts ?? req.body.canReceiveAlerts ?? true,
        custom_music: req.body.custom_music ?? req.body.canPlayMusic ?? false,
        camera_snapshot: req.body.camera_snapshot ?? req.body.canViewCamera ?? false,
        cradle_controls: req.body.cradle_controls ?? req.body.canControlCradle ?? false,
      };
    }

    try {
      const updated = await caregiversService.updateTemporaryPermissions(permissionId, parentId, permissions);
      res.json({ success: true, data: updated });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error updating caregiver permissions.' });
    }
  }

  /**
   * PATCH /caregivers/temporary-permission/:id/extend
   * Parent extends caregiver access duration (+15m, +30m, +1h, custom)
   */
  public static async extendAccess(req: AuthenticatedRequest, res: Response) {
    const permissionId = req.params.id || req.body.permissionId || req.body.sessionId || req.body.caregiverId;
    const parentId = req.user?.userId;
    const { extensionMinutes } = req.body;

    if (!parentId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!extensionMinutes || typeof extensionMinutes !== 'number') {
      return res.status(400).json({ error: 'extensionMinutes number is required.' });
    }

    try {
      const updated = await caregiversService.extendTemporaryAccess(permissionId, parentId, extensionMinutes);
      res.json({ success: true, data: updated });
    } catch (e: any) {
      const status = e.statusCode || 400;
      res.status(status).json({ success: false, error: e.message || 'Error extending caregiver access.' });
    }
  }

  /**
   * GET /caregiver/access (Caregiver API alias to query active access)
   */
  public static async getCaregiverAccess(req: AuthenticatedRequest, res: Response) {
    const caregiverId = req.user?.userId;

    if (!caregiverId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const permissions = await caregiversService.getActivePermissions(caregiverId);
      const active = permissions.length > 0 ? permissions[0] : null;

      if (active) {
        console.log('[Caregiver] Active permission found');
        console.log(`[Caregiver] Permission expires at ${active.expiresAt}`);
        return res.json({
          success: true,
          hasAccess: true,
          babyId: active.babyId,
          expiresAt: active.expiresAt,
          permissions: {
            liveMonitoring: active.permissions?.live_monitoring ?? true,
            camera: active.permissions?.camera_snapshot ?? true,
            alerts: active.permissions?.emergency_alerts ?? true,
            customLullabies: active.permissions?.custom_music ?? false,
          },
          data: active,
        });
      }

      // Check status for required debug log outputs
      const statusCheck = await caregiversService.checkCaregiverPermissionStatus(caregiverId);
      if (statusCheck.revoked) {
        console.log('[Caregiver] Permission revoked');
      } else if (statusCheck.expired) {
        console.log('[Caregiver] Permission expired');
      }

      return res.json({
        success: true,
        hasAccess: false,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ success: false, error: e.message || 'Error fetching caregiver access.' });
    }
  }

  /**
   * GET /caregivers/history
   */
  public static async getHistory(req: AuthenticatedRequest, res: Response) {
    const babyId = req.query.babyId as string;
    const requesterId = req.user?.userId;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!babyId) {
      return res.status(400).json({ error: 'babyId query parameter is required.' });
    }

    try {
      const history = await caregiversService.getAccessHistory(babyId, requesterId);
      res.json({ success: true, data: history });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({ success: false, error: e.message || 'Error fetching caregiver access history.' });
    }
  }
}
