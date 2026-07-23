import { Router } from 'express';
import { CaregiversController } from './caregivers.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/invite', CaregiversController.invite);
router.post('/accept', CaregiversController.accept);
router.get('/', CaregiversController.list);
router.delete('/:id', CaregiversController.revoke);

export default router;
