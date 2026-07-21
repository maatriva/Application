import { Router, Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { config } from '../config/config';

// Authentication middleware helper
function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ error: 'Access token required.' });

  jwt.verify(token, config.jwtSecret, (err, decoded: any) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token.' });
    req.body.user = decoded; // inject decoded jwt session
    next();
  });
}

export function createBabiesRouter(dbPool: Pool): Router {
  const router = Router();

  // POST /babies
  router.post('/', authenticateToken, async (req: Request, res: Response) => {
    const { name, birthDate, gender, user } = req.body;
    const parentId = user.userId;

    if (!name || !birthDate || !gender) {
      return res.status(400).json({ error: 'Name, birthDate, and gender are required.' });
    }

    try {
      const insertRes = await dbPool.query(
        `INSERT INTO babies (parent_id, name, birth_date, gender)
         VALUES ($1, $2, $3, $4) RETURNING id, parent_id as "parentId", name, birth_date as "birthDate", gender`,
        [parentId, name, birthDate, gender]
      );
      res.status(201).json(insertRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal baby registration error', details: e.message });
    }
  });

  // GET /babies (List babies matching parent_id or accepted caregiver mapping)
  router.get('/', authenticateToken, async (req: Request, res: Response) => {
    const userId = req.body.user.userId;

    try {
      const babiesRes = await dbPool.query(
        `SELECT b.id, b.name, b.birth_date as "birthDate", b.gender, b.parent_id as "parentId"
         FROM babies b
         WHERE b.parent_id = $1
         UNION
         SELECT b.id, b.name, b.birth_date as "birthDate", b.gender, b.parent_id as "parentId"
         FROM babies b
         JOIN caregivers c ON c.baby_id = b.id
         WHERE c.user_id = $1 AND c.status = 'accepted'`,
        [userId]
      );
      res.json(babiesRes.rows);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch babies error', details: e.message });
    }
  });

  // GET /babies/:id
  router.get('/:id', authenticateToken, async (req: Request, res: Response) => {
    const babyId = req.params.id;
    const userId = req.body.user.userId;

    try {
      const authCheck = await dbPool.query(
        `SELECT b.id FROM babies b
         WHERE b.id = $1 AND (
           b.parent_id = $2 OR EXISTS (
             SELECT 1 FROM caregivers c WHERE c.baby_id = $1 AND c.user_id = $2 AND c.status = 'accepted'
           )
         )`,
        [babyId, userId]
      );

      if (authCheck.rows.length === 0) {
        return res.status(403).json({ error: 'Access denied to baby profile.' });
      }

      const babyRes = await dbPool.query(
        'SELECT id, name, birth_date as "birthDate", gender, parent_id as "parentId" FROM babies WHERE id = $1',
        [babyId]
      );
      res.json(babyRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch baby error', details: e.message });
    }
  });

  // PATCH /babies/:id
  router.patch('/:id', authenticateToken, async (req: Request, res: Response) => {
    const babyId = req.params.id;
    const userId = req.body.user.userId;
    const { name, birthDate, gender } = req.body;

    try {
      // Only parents are authorized to modify profiles
      const parentCheck = await dbPool.query('SELECT parent_id FROM babies WHERE id = $1', [babyId]);
      if (parentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Baby not found.' });
      }
      if (parentCheck.rows[0].parent_id !== userId) {
        return res.status(403).json({ error: 'Only primary parent can update profile.' });
      }

      const updateRes = await dbPool.query(
        `UPDATE babies SET name = COALESCE($1, name), birth_date = COALESCE($2, birth_date), gender = COALESCE($3, gender), updated_at = NOW()
         WHERE id = $4 RETURNING id, name, birth_date as "birthDate", gender`,
        [name, birthDate, gender, babyId]
      );
      res.json(updateRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal update baby error', details: e.message });
    }
  });

  return router;
}
