import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for raw sensor statistics & telemetry aggregation
router.get('/stats', (req, res) => {
  res.json({ message: 'Sensors telemetry stats route active' });
});

export default router;
