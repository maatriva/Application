import { Response } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { CaregiversService } from './caregivers.service';

const caregiversService = new CaregiversService();

export class CaregiversController {
  public static async invite(req: AuthenticatedRequest, res: Response) {
    const { babyId, caregiverEmail, accessLevel } = req.body;
    const parentId = req.user?.userId;

    if (!parentId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!babyId || !caregiverEmail) {
      return res.status(400).json({ error: 'babyId and caregiverEmail are required.' });
    }

    try {
      const invitation = await caregiversService.inviteCaregiver({
        babyId,
        caregiverEmail,
        accessLevel,
        parentId,
      });
      res.status(201).json(invitation);
    } catch (e: any) {
      if (e.message.includes('not found') || e.message.includes('not registered')) {
        return res.status(404).json({ error: e.message });
      }
      res.status(403).json({ error: e.message });
    }
  }

  public static async accept(req: AuthenticatedRequest, res: Response) {
    const { invitationId } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!invitationId) {
      return res.status(400).json({ error: 'invitationId is required.' });
    }

    try {
      const result = await caregiversService.acceptInvitation(invitationId, userId);
      res.json(result);
    } catch (e: any) {
      if (e.message.includes('not found')) {
        return res.status(404).json({ error: e.message });
      }
      res.status(403).json({ error: e.message });
    }
  }

  public static async list(req: AuthenticatedRequest, res: Response) {
    const babyId = req.query.babyId as string;

    if (!babyId) {
      return res.status(400).json({ error: 'babyId query parameter is required.' });
    }

    try {
      const list = await caregiversService.listCaregivers(babyId);
      res.json(list);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch caregivers error', details: e.message });
    }
  }

  public static async revoke(req: AuthenticatedRequest, res: Response) {
    const mappingId = req.params.id;
    const requesterId = req.user?.userId;

    if (!requesterId) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    try {
      const result = await caregiversService.revokeAccess(mappingId, requesterId);
      res.json(result);
    } catch (e: any) {
      if (e.message.includes('not found')) {
        return res.status(404).json({ error: e.message });
      }
      res.status(403).json({ error: e.message });
    }
  }
}
