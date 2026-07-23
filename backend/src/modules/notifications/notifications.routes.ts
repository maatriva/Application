import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for notification token registrations and history
router.get('/history', (req, res) => {
  res.json({ message: 'Notifications history route active' });
});

export default router;
