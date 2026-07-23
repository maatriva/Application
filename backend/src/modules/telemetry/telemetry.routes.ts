import { Router } from 'express';
import { TelemetryController } from './telemetry.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// Apply authentication token middleware
router.use(authenticateToken);

router.get('/latest/:babyId', TelemetryController.getLatest);
router.get('/history/:babyId', TelemetryController.getHistory);

export default router;
