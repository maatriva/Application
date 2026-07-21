import { Router, Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { config } from '../config/config';

function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ error: 'Access token required.' });

  jwt.verify(token, config.jwtSecret, (err, decoded: any) => {
    if (err) return res.status(403).json({ error: 'Invalid token.' });
    req.body.user = decoded;
    next();
  });
}

export function createCaregiversRouter(dbPool: Pool): Router {
  const router = Router();

  // POST /caregivers/invite (Parent invites caregiver by email to monitor a baby)
  router.post('/invite', authenticateToken, async (req: Request, res: Response) => {
    const { babyId, caregiverEmail, accessLevel } = req.body;
    const parentId = req.body.user.userId;

    if (!babyId || !caregiverEmail) {
      return res.status(400).json({ error: 'babyId and caregiverEmail are required.' });
    }

    try {
      // 1. Verify that the inviter is the primary parent
      const babyCheck = await dbPool.query('SELECT parent_id FROM babies WHERE id = $1', [babyId]);
      if (babyCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Baby profile not found.' });
      }
      if (babyCheck.rows[0].parent_id !== parentId) {
        return res.status(403).json({ error: 'Only primary parents can invite caregivers.' });
      }

      // 2. Resolve caregiver's user ID
      const userRes = await dbPool.query('SELECT id FROM users WHERE email = $1', [caregiverEmail]);
      if (userRes.rows.length === 0) {
        return res.status(404).json({ error: 'Invited user email has not registered an account with Maatriva yet.' });
      }
      const caregiverId = userRes.rows[0].id;

      // 3. Create mapping entry
      const insertRes = await dbPool.query(
        `INSERT INTO caregivers (baby_id, user_id, access_level, status, invited_by)
         VALUES ($1, $2, $3, 'pending', $4)
         ON CONFLICT (baby_id, user_id) DO UPDATE SET access_level = $3
         RETURNING id, baby_id as "babyId", user_id as "userId", access_level as "accessLevel", status`,
        [babyId, caregiverId, accessLevel || 'monitor', parentId]
      );

      res.status(201).json(insertRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal caregiver invitation error', details: e.message });
    }
  });

  // POST /caregivers/accept (Caregiver accepts invitation)
  router.post('/accept', authenticateToken, async (req: Request, res: Response) => {
    const { invitationId } = req.body;
    const userId = req.body.user.userId;

    if (!invitationId) {
      return res.status(400).json({ error: 'invitationId is required.' });
    }

    try {
      // Verify invitation belongs to user
      const inviteCheck = await dbPool.query('SELECT user_id FROM caregivers WHERE id = $1', [invitationId]);
      if (inviteCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Invitation not found.' });
      }
      if (inviteCheck.rows[0].user_id !== userId) {
        return res.status(403).json({ error: 'Access denied: invitation belongs to another user.' });
      }

      const updateRes = await dbPool.query(
        `UPDATE caregivers SET status = 'accepted' WHERE id = $1
         RETURNING id, baby_id as "babyId", user_id as "userId", access_level as "accessLevel", status`,
        [invitationId]
      );

      res.json(updateRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal invitation acceptance error', details: e.message });
    }
  });

  // GET /caregivers (List caregivers for a specific baby)
  router.get('/', authenticateToken, async (req: Request, res: Response) => {
    const babyId = req.query.babyId as string;

    if (!babyId) {
      return res.status(400).json({ error: 'babyId query parameter is required.' });
    }

    try {
      const list = await dbPool.query(
        `SELECT c.id as "invitationId", c.access_level as "accessLevel", c.status,
                u.id as "userId", u.email, u.first_name as "firstName", u.last_name as "lastName"
         FROM caregivers c
         JOIN users u ON u.id = c.user_id
         WHERE c.baby_id = $1`,
        [babyId]
      );
      res.json(list.rows);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch caregivers error', details: e.message });
    }
  });

  // DELETE /caregivers/:id (Revoke caregiver access)
  router.delete('/:id', authenticateToken, async (req: Request, res: Response) => {
    const mappingId = req.params.id;
    const requesterId = req.body.user.userId;

    try {
      // Access check: only primary parent or the caregiver themselves can delete the mapping
      const record = await dbPool.query(
        `SELECT c.user_id as "caregiverId", b.parent_id as "parentId"
         FROM caregivers c
         JOIN babies b ON b.id = c.baby_id
         WHERE c.id = $1`,
        [mappingId]
      );

      if (record.rows.length === 0) {
        return res.status(404).json({ error: 'Mapping not found.' });
      }

      const { caregiverId, parentId } = record.rows[0];
      if (requesterId !== caregiverId && requesterId !== parentId) {
        return res.status(403).json({ error: 'Access denied: only parent or caregiver can revoke permissions.' });
      }

      await dbPool.query('DELETE FROM caregivers WHERE id = $1', [mappingId]);
      res.json({ message: 'Caregiver access revoked successfully.' });
    } catch (e: any) {
      res.status(500).json({ error: 'Internal revoke access error', details: e.message });
    }
  });

  return router;
}
