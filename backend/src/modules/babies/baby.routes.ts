import { Router } from 'express';
import { BabyController } from './baby.controller';
import { authenticateToken } from '../../middleware/auth.middleware';

const router = Router();

// Apply authentication middleware to all baby routes
router.use(authenticateToken);

router.post('/', BabyController.create);
router.get('/', BabyController.list);
router.get('/:id', BabyController.getById);
router.put('/:id', BabyController.update);
router.delete('/:id', BabyController.delete);

export default router;
