import { Router } from 'express';
import { MusicController } from './music.controller';

const router = Router();

// 1. Music Catalog & Stats
router.get('/', MusicController.getCatalog);
router.get('/stats', MusicController.getStats);

// 2. Duplicate Detection
router.post('/check-duplicates', MusicController.checkDuplicates);

// 3. Bulk Upload & Background Job Monitoring
router.post('/upload-bulk', MusicController.uploadBulk);
router.get('/jobs/:jobId', MusicController.getJobStatus);

// 4. Batch Operations (Delete, Category, Language, Status, Export)
router.patch('/batch', MusicController.batchOperation);

// 5. Single Track Actions
router.patch('/:id', MusicController.updateTrack);
router.delete('/:id', MusicController.deleteTrack);

export default router;
