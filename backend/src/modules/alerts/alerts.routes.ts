import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for alert acknowledging endpoint
router.post('/:id/acknowledge', (req, res) => {
  res.json({ message: 'Alert acknowledged route active' });
});

export default router;
