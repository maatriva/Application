import { Router } from 'express';
import { authenticateToken, requireRole } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';

const router = Router();

router.use(authenticateToken);
router.use(requireRole([UserRole.DOCTOR, UserRole.ADMIN]));

// Placeholder for Doctor consultation sessions
router.get('/appointments', (req, res) => {
  res.json({ message: 'Doctor appointments route active' });
});

export default router;
