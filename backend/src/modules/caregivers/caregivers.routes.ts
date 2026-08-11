import { Router } from 'express';
import { CaregiversController } from './caregivers.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/invite', CaregiversController.invite);
router.get('/', CaregiversController.list);
router.patch('/:id', CaregiversController.update);
router.delete('/:id', CaregiversController.revoke);
router.post('/accept', CaregiversController.accept);
router.post('/invitation/accept', CaregiversController.accept);
router.post('/access/accept', CaregiversController.accept);
router.post('/invitation/reject', CaregiversController.reject);
router.post('/grant-temporary', CaregiversController.grantTemporary);
router.post('/generate-qr', CaregiversController.grantTemporary);
router.post('/access/generate-qr', CaregiversController.grantTemporary);
router.get('/active-permissions', CaregiversController.getActivePermissions);
router.get('/access', CaregiversController.getCaregiverAccess);
router.get('/access/active', CaregiversController.getCaregiverAccess);
router.delete('/temporary-permission/:id', CaregiversController.revokeTemporaryPermission);
router.patch('/temporary-permission/:id/permissions', CaregiversController.updatePermissions);
router.patch('/temporary-permission/:id/extend', CaregiversController.extendAccess);

export default router;
