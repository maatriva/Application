import { Router } from 'express';
import { CaregiversController } from './caregivers.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/server-time', CaregiversController.serverTime);
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
router.get('/invitations', CaregiversController.listInvitations);
router.get('/active-permissions', CaregiversController.getActivePermissions);
router.get('/permissions', CaregiversController.getActivePermissions);
router.get('/access', CaregiversController.getCaregiverAccess);
router.get('/access/active', CaregiversController.getCaregiverAccess);
router.get('/history', CaregiversController.getHistory);
router.get('/access/history', CaregiversController.getHistory);
router.delete('/temporary-permission/:id', CaregiversController.revokeTemporaryPermission);
router.delete('/temporary-permissions/:id', CaregiversController.revokeTemporaryPermission);

router.patch('/temporary-permission/:id/permissions', CaregiversController.updatePermissions);
router.put('/temporary-permission/:id/permissions', CaregiversController.updatePermissions);
router.patch('/temporary-permissions/:id/permissions', CaregiversController.updatePermissions);
router.put('/temporary-permissions/:id/permissions', CaregiversController.updatePermissions);
router.patch('/:id/permissions', CaregiversController.updatePermissions);
router.put('/:id/permissions', CaregiversController.updatePermissions);
router.patch('/permissions', CaregiversController.updatePermissions);
router.put('/permissions', CaregiversController.updatePermissions);

router.patch('/temporary-permission/:id/extend', CaregiversController.extendAccess);
router.post('/temporary-permission/:id/extend', CaregiversController.extendAccess);
router.put('/temporary-permission/:id/extend', CaregiversController.extendAccess);
router.patch('/temporary-permissions/:id/extend', CaregiversController.extendAccess);
router.post('/temporary-permissions/:id/extend', CaregiversController.extendAccess);
router.put('/temporary-permissions/:id/extend', CaregiversController.extendAccess);

export default router;
