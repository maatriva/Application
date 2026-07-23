import { Router } from 'express';
import { DevicesController } from './devices.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/pair', DevicesController.pair);
router.get('/', DevicesController.list);
router.get('/:id/latest', DevicesController.getLatest);
router.get('/:id/history', DevicesController.getHistory);
router.get('/:id/alerts', DevicesController.getAlerts);

export default router;
