import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Placeholder for controlling smart lullabies and sounds played on the cradle
router.post('/play', (req, res) => {
  res.json({ message: 'Play music control route active' });
});

export default router;
