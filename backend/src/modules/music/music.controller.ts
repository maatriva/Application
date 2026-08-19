import { Request, Response } from 'express';
import { MusicService } from './music.service';
import { MusicFilterQuery, BatchOperationPayload } from './music.types';

const musicService = new MusicService();

export class MusicController {
  // GET /api/music
  static async getCatalog(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      const userId = authUser?.userId || (req.query.uploadedBy as string);
      const query: MusicFilterQuery = {
        search: req.query.search as string,
        category: req.query.category as string,
        language: req.query.language as string,
        isActive: req.query.isActive as string,
        isPremium: req.query.isPremium as string,
        sortBy: req.query.sortBy as any,
        sortOrder: req.query.sortOrder as any,
        page: req.query.page ? Number(req.query.page) : 1,
        limit: req.query.limit ? Number(req.query.limit) : 50,
        uploadedBy: userId,
      };

      const result = await musicService.getMusicCatalog(query, userId);
      res.json({
        success: true,
        data: result.tracks,
        total: result.total,
        page: query.page,
        limit: query.limit,
      });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Failed to fetch music catalog' });
    }
  }

  // GET /api/music/bgm
  static async getBgm(req: Request, res: Response): Promise<void> {
    try {
      const tracks = await musicService.getBgmTracks();
      res.json({ success: true, data: tracks, tracks });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Failed to fetch BGM tracks' });
    }
  }

  // GET /api/music/stats
  static async getStats(req: Request, res: Response): Promise<void> {
    try {
      const stats = await musicService.getMusicStats();
      res.json({ success: true, data: stats });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Failed to calculate music stats' });
    }
  }

  // POST /api/music/check-duplicates
  static async checkDuplicates(req: Request, res: Response): Promise<void> {
    try {
      const { files } = req.body;
      if (!files || !Array.isArray(files)) {
        res.status(400).json({ success: false, error: 'Array of files is required for duplicate check' });
        return;
      }

      const result = await musicService.checkDuplicates({ files });
      res.json({ success: true, data: result });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Duplicate check failed' });
    }
  }

  // POST /api/music/upload-bulk
  static async uploadBulk(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      const userId = authUser?.userId;
      const category = req.body.category || 'Auto-Detect';
      const language = req.body.language || 'English';

      let filesToProcess: Array<{
        originalname: string;
        buffer: Buffer;
        size: number;
        mimetype?: string;
        relativePath?: string;
      }> = [];

      // Check if files attached via req.files or custom JSON base64 payload
      const reqAny = req as any;
      if (reqAny.files && Array.isArray(reqAny.files)) {
        filesToProcess = reqAny.files.map((f: any) => ({
          originalname: f.originalname,
          buffer: f.buffer,
          size: f.size,
          mimetype: f.mimetype,
          relativePath: f.relativePath || (req.body.relativePaths && req.body.relativePaths[f.originalname]),
        }));
      } else if (req.body.files && Array.isArray(req.body.files)) {
        // Direct JSON base64 array payload option
        filesToProcess = req.body.files.map((f: any) => ({
          originalname: f.name || f.filename,
          buffer: Buffer.from(f.base64Data || '', 'base64'),
          size: f.size || (f.base64Data ? Buffer.from(f.base64Data, 'base64').length : 0),
          mimetype: f.type,
          relativePath: f.path || f.relativePath || f.name,
        }));
      }

      if (filesToProcess.length === 0) {
        res.status(400).json({
          success: false,
          error: 'No audio files provided. Please upload between 1 and 500 audio/zip files.',
        });
        return;
      }

      const jobStatus = await musicService.processBulkUpload(filesToProcess, category, language, userId);
      res.status(202).json({
        success: true,
        message: `Started bulk processing for ${filesToProcess.length} files.`,
        data: jobStatus,
      });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Bulk upload process failed' });
    }
  }

  // GET /api/music/jobs/:jobId
  static getJobStatus(req: Request, res: Response): void {
    const { jobId } = req.params;
    const status = musicService.getJobStatus(jobId);
    if (!status) {
      res.status(404).json({ success: false, error: `Batch job '${jobId}' not found.` });
      return;
    }
    res.json({ success: true, data: status });
  }

  // PATCH /api/music/batch
  static async batchOperation(req: Request, res: Response): Promise<void> {
    try {
      const payload: BatchOperationPayload = req.body;
      if (!payload.action || !payload.trackIds || !Array.isArray(payload.trackIds)) {
        res.status(400).json({ success: false, error: 'Valid action and array of trackIds are required.' });
        return;
      }

      const result = await musicService.executeBatchOperation(payload);
      if (!result.success) {
        res.status(400).json({ success: false, error: result.message });
        return;
      }

      if (payload.action === 'export_metadata' && result.csvContent) {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="music_metadata_export_${Date.now()}.csv"`);
        res.status(200).send(result.csvContent);
        return;
      }

      res.json({ success: true, data: result });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Batch operation failed' });
    }
  }

  // PATCH /api/music/:id
  static async updateTrack(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const updated = await musicService.updateTrack(id, req.body);
      if (!updated) {
        res.status(404).json({ success: false, error: 'Music track not found' });
        return;
      }
      res.json({ success: true, data: updated });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Failed to update music track' });
    }
  }

  // DELETE /api/music/:id
  static async deleteTrack(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const success = await musicService.deleteTrack(id);
      if (!success) {
        res.status(404).json({ success: false, error: 'Music track not found' });
        return;
      }
      res.json({ success: true, message: 'Track deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message || 'Failed to delete music track' });
    }
  }

  // GET /api/music/custom (Parent API: Fetch all owned custom lullabies)
  static async getCustom(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      if (!authUser || !authUser.userId) {
        res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
        return;
      }

      console.log('[Music] GET /music/custom');
      const tracks = await musicService.getCustomLullabies(authUser.userId);
      console.log(`[Music] Database returned ${tracks.length} songs`);
      console.log(`[Music] Songs received: ${tracks.length}`);
      res.json({ success: true, data: tracks, total: tracks.length });
    } catch (err: any) {
      const status = err.statusCode || 500;
      res.status(status).json({ success: false, error: err.message || 'Failed to fetch custom parent lullabies' });
    }
  }

  // POST /api/music/custom (Parent API: Create custom lullaby with DEFAULT visibility = PRIVATE)
  static async createCustom(req: Request, res: Response): Promise<void> {
    try {
      console.log('[Music] POST /music/custom');
      const authUser = (req as any).user;
      if (!authUser || !authUser.userId) {
        res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
        return;
      }

      console.log(`[Music] Authenticated User: ${authUser.userId}`);

      let storageUrl = req.body.fileUrl || req.body.storageUrl || req.body.audioPath;
      const isRecording = req.body?.category === 'Parent Voice' || req.body?.category === 'Parent Recordings' || req.body?.sourceType === 'RECORDED';
      const prefix = isRecording ? '/uploads/recordings/' : '/uploads/music/';

      if (storageUrl && (storageUrl.includes('..') || storageUrl.includes('\\'))) {
        res.status(400).json({ success: false, error: 'Invalid file path traversal in fileUrl.' });
        return;
      }

      if (req.file) {
        const savedFilename = req.file.filename;
        console.log(`[Music] Saving File: ${savedFilename} (destination: ${prefix})`);
        storageUrl = `${prefix}${savedFilename}`;
      } else if (storageUrl) {
        console.log(`[Music] Saving File: ${storageUrl}`);
      } else {
        console.log('[Music] Saving File: default_audio.mp3');
      }

      console.log('[Music] Creating Database Record');
      const payload = {
        ...req.body,
        storageUrl,
      };

      const newTrack = await musicService.createCustomTrack(authUser.userId, payload);
      console.log(`[Music] Database Saved: ${newTrack.id}`);
      console.log('[Music] Returning Success');

      res.status(201).json({ success: true, data: newTrack });
    } catch (err: any) {
      const status = err.statusCode || 400;
      res.status(status).json({ success: false, error: err.message || 'Failed to create custom lullaby' });
    }
  }

  // PATCH /api/music/custom/:id/share (Parent API: Toggle share with caregivers per song)
  static async shareCustom(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      const { id } = req.params;
      const { shareWithCaregivers } = req.body;

      if (!authUser || !authUser.userId) {
        res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
        return;
      }

      if (shareWithCaregivers === undefined) {
        res.status(400).json({ success: false, error: 'shareWithCaregivers boolean flag is required.' });
        return;
      }

      const updated = await musicService.updateTrackShareStatus(id, authUser.userId, Boolean(shareWithCaregivers));
      res.json({ success: true, data: updated });
    } catch (err: any) {
      const status = err.statusCode || 400;
      res.status(status).json({ success: false, error: err.message || 'Failed to update song sharing status' });
    }
  }

  // PATCH /api/music/custom/share-all (Parent API: Toggle share for ENTIRE custom folder)
  static async shareAllCustom(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      const { shareWithCaregivers } = req.body;

      if (!authUser || !authUser.userId) {
        res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
        return;
      }

      if (shareWithCaregivers === undefined) {
        res.status(400).json({ success: false, error: 'shareWithCaregivers boolean flag is required.' });
        return;
      }

      const result = await musicService.updateAllCustomTracksShareStatus(authUser.userId, Boolean(shareWithCaregivers));
      res.json({ success: true, data: result });
    } catch (err: any) {
      const status = err.statusCode || 400;
      res.status(status).json({ success: false, error: err.message || 'Failed to batch update folder sharing status' });
    }
  }

  // GET /api/music/shared (Caregiver API: Fetch shared custom lullabies)
  static async getSharedForCaregiver(req: Request, res: Response): Promise<void> {
    try {
      const authUser = (req as any).user;
      if (!authUser || !authUser.userId) {
        res.status(401).json({ success: false, error: 'Unauthorized: Authentication required.' });
        return;
      }

      const tracks = await musicService.getSharedLullabiesForCaregiver(authUser.userId);
      res.json({ success: true, data: tracks, total: tracks.length });
    } catch (err: any) {
      const status = err.statusCode || 403;
      res.status(status).json({
        success: false,
        error: err.message || 'Forbidden: Custom parent lullabies are private unless granted by parent.',
        code: err.code || 'ACCESS_DENIED',
      });
    }
  }
}
