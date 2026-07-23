import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for user profiles management
router.get('/profile', (req, res) => {
  res.json({ message: 'User profile route active' });
});

export default router;
