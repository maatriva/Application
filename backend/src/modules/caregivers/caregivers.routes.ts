import { Router } from 'express';
import { CaregiversController } from './caregivers.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/invite', CaregiversController.invite);
router.get('/', CaregiversController.list);
router.patch('/:id', CaregiversController.update);
router.delete('/:id', CaregiversController.revoke);
router.post('/invitation/accept', CaregiversController.accept);
router.post('/invitation/reject', CaregiversController.reject);
router.get('/invitations', CaregiversController.listInvitations);

export default router;
