import { Router } from 'express';
import { TelemetryController } from './telemetry.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// Ingestion endpoint does NOT require JWT authentication
router.post('/', TelemetryController.ingest);

// Apply authentication token middleware
router.use(authenticateToken);

router.get('/latest/:babyId', TelemetryController.getLatest);
router.get('/history/:babyId', TelemetryController.getHistory);
router.get('/sensor-report/:babyId', TelemetryController.getSensorReport);

export default router;
