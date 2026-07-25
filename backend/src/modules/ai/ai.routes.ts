import { Router } from 'express';
import { AiController } from './ai.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// Expose the insight generation route under /insight
router.post('/insight', authenticateToken, AiController.getInsight);

// Expose the historical AI report route under /reports/:babyId
router.get('/reports/:babyId', authenticateToken, AiController.getReport);

export default router;
