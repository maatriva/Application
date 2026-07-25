import { Response } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { CaregiversService } from './caregivers.service';

const caregiversService = new CaregiversService();

export class CaregiversController {
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

    if (!babyId) {
      return res.status(400).json({ error: 'babyId query parameter is required.' });
    }

    try {
      const data = await caregiversService.listCaregivers(babyId);
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
}
