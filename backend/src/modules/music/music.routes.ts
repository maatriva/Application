import { Router } from 'express';
import { MusicController } from './music.controller';
import { authenticateToken, optionalAuthenticateToken, requireRole } from '../../middleware/auth.middleware';
import { UserRole } from '@prisma/client';
import { getMusicUploadsDirectory, getRecordingsUploadsDirectory } from '../../config/uploads.config';

import { env } from '../../config/env';
import multer from 'multer';
import path from 'path';

const storage = multer.diskStorage({
  destination: (req, _file, cb) => {
    const category = req.body?.category;
    const isRecording = category === 'Parent Voice' || category === 'Parent Recordings' || req.body?.sourceType === 'RECORDED';
    const destDir = isRecording ? getRecordingsUploadsDirectory() : getMusicUploadsDirectory();
    cb(null, destDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.mp3';
    const safeFilename = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}${ext}`;
    cb(null, safeFilename);
  },
});

const allowedAudioExtensions = new Set(['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac', '.webm', '.3gp']);

const upload = multer({
  storage,
  limits: { fileSize: env.MAX_MUSIC_UPLOAD_MB * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const mime = (file.mimetype || '').toLowerCase();
    const isAudioMime = mime.startsWith('audio/') || mime === 'application/octet-stream';
    const isAllowedExt = allowedAudioExtensions.has(ext);

    if (isAllowedExt && isAudioMime) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid audio file type '${ext}'. Allowed types: MP3, WAV, M4A, AAC, OGG, FLAC, WEBM.`));
    }
  },
});

const router = Router();

// 1. Music Catalog & Stats (optional auth to return user's custom uploads)
router.get('/bgm', MusicController.getBgm);
router.get('/', optionalAuthenticateToken, MusicController.getCatalog);
router.get('/stats', MusicController.getStats);

// 2. Duplicate Detection
router.post('/check-duplicates', MusicController.checkDuplicates);

// 3. Bulk Upload & Custom Music Creation (Caregivers restricted; PARENT and ADMIN allowed)
router.post('/upload-bulk', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.uploadBulk);
router.get('/jobs/:jobId', MusicController.getJobStatus);

// 4. Batch Operations (Delete, Category, Language, Status, Export)
router.patch('/batch', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.batchOperation);

// 5. Custom Parent Lullabies & Upload APIs (Parent ownership & Privacy)
router.get('/custom', authenticateToken, MusicController.getCustom);
router.post('/custom', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), upload.single('audioFile'), MusicController.createCustom);
router.post('/upload', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), upload.single('audioFile'), MusicController.createCustom);
router.patch('/custom/share-all', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.shareAllCustom);
router.patch('/custom/:id/share', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.shareCustom);

// 6. Caregiver Shared Custom Lullabies API (Read-only)
router.get('/shared', authenticateToken, MusicController.getSharedForCaregiver);

// 7. Single Track Actions
router.patch('/:id', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.updateTrack);
router.delete('/:id', authenticateToken, requireRole([UserRole.PARENT, UserRole.ADMIN]), MusicController.deleteTrack);

export default router;

