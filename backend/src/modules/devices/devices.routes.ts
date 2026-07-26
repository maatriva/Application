import { Router } from 'express';
import { DevicesController } from './devices.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.post('/register', DevicesController.register);

router.use(authenticateToken);

router.post('/pair', DevicesController.pair);
router.get('/', DevicesController.list);
router.get('/:id/latest', DevicesController.getLatest);
router.get('/:id/history', DevicesController.getHistory);
router.get('/:id/alerts', DevicesController.getAlerts);
router.patch('/:id/rename', DevicesController.rename);
router.patch('/:id/reassign', DevicesController.reassign);
router.delete('/:id/unpair', DevicesController.unpair);

export default router;
