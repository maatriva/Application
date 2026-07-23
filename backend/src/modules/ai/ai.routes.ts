import { Router } from 'express';
import { AiController } from './ai.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// Expose the insight generation route under /insight (optionally authenticated)
router.post('/insight', authenticateToken, AiController.getInsight);

export default router;
