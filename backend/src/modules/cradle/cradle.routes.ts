import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for cradle controls (e.g. swing speed, motion status)
router.get('/status', (req, res) => {
  res.json({ message: 'Cradle status route active' });
});

export default router;
