import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for sleep score and weekly reports downloads
router.get('/weekly', (req, res) => {
  res.json({ message: 'Weekly reports route active' });
});

export default router;
