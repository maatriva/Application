import { Router } from 'express';
import { authenticateToken } from '../../middleware/auth.middleware';
import { AlertsController } from './alerts.controller';

const router = Router();

router.use(authenticateToken);

// Alerts endpoints
router.get('/', AlertsController.getAlerts);
router.patch('/:id/read', AlertsController.markAsRead);
router.delete('/:id', AlertsController.deleteAlert);
router.delete('/', AlertsController.clearAll);

export default router;
