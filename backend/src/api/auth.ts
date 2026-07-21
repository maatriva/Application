import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { config } from '../config/config';

export function createAuthRouter(dbPool: Pool): Router {
  const router = Router();

  // POST /auth/register
  router.post('/register', async (req: Request, res: Response) => {
    const { email, password, firstName, lastName, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    try {
      const emailCheck = await dbPool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (emailCheck.rows.length > 0) {
        return res.status(409).json({ error: 'User with this email already exists.' });
      }

      const passwordHash = await bcrypt.hash(password, 10);
      const userRole = role || 'caregiver'; // default role

      const insertRes = await dbPool.query(
        `INSERT INTO users (email, password_hash, role, first_name, last_name)
         VALUES ($1, $2, $3, $4, $5) RETURNING id, email, role, first_name as "firstName", last_name as "lastName"`,
        [email, passwordHash, userRole, firstName, lastName]
      );

      res.status(201).json(insertRes.rows[0]);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal register error', details: e.message });
    }
  });

  // POST /auth/login
  router.post('/login', async (req: Request, res: Response) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    try {
      const userRes = await dbPool.query(
        'SELECT id, email, password_hash as "passwordHash", role FROM users WHERE email = $1',
        [email]
      );

      if (userRes.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }

      const user = userRes.rows[0];
      const validPassword = await bcrypt.compare(password, user.passwordHash);

      if (!validPassword) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }

      // Generate JWT Token
      const token = jwt.sign(
        { userId: user.id, role: user.role },
        config.jwtSecret,
        { expiresIn: config.jwtExpiration as any }
      );

      res.json({
        token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
        },
      });
    } catch (e: any) {
      res.status(500).json({ error: 'Internal login error', details: e.message });
    }
  });

  return router;
}
