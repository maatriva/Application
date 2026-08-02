import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { prisma } from '../../config/database';
import {
  MusicTrackItem,
  MusicFilterQuery,
  MusicStatsResponse,
  DuplicateCheckRequest,
  DuplicateCheckResponse,
  BatchOperationPayload,
  UploadBatchStatus,
} from './music.types';

// In-memory store for jobs and initial fallback data when DB is not populated
const jobStore = new Map<string, UploadBatchStatus>();

const UPLOAD_DIR = path.join(process.cwd(), 'uploads', 'music');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// Default initial catalog seed if database is empty
const INITIAL_SEED_TRACKS: MusicTrackItem[] = [];

let inMemoryCatalog: MusicTrackItem[] = [...INITIAL_SEED_TRACKS];

export class MusicService {
  // 1. Fetch filtered music list with pagination & search
  async getMusicCatalog(query: MusicFilterQuery): Promise<{ tracks: MusicTrackItem[]; total: number }> {
    try {
      // Try DB search first
      const whereClause: any = {};
      if (query.category && query.category !== 'All') {
        whereClause.category = query.category;
      }
      if (query.language && query.language !== 'All') {
        whereClause.language = query.language;
      }
      if (query.isActive !== undefined && query.isActive !== 'all') {
        whereClause.isActive = query.isActive === 'true';
      }
      if (query.isPremium !== undefined && query.isPremium !== 'all') {
        whereClause.isPremium = query.isPremium === 'true';
      }
      if (query.search) {
        whereClause.OR = [
          { title: { contains: query.search, mode: 'insensitive' } },
          { artist: { contains: query.search, mode: 'insensitive' } },
          { category: { contains: query.search, mode: 'insensitive' } },
        ];
      }

      const orderBy: any = {};
      const sortBy = query.sortBy || 'newest';
      const order = query.sortOrder || 'desc';

      if (sortBy === 'newest') orderBy.uploadedAt = order;
      else if (sortBy === 'oldest') orderBy.uploadedAt = order === 'desc' ? 'asc' : 'desc';
      else if (sortBy === 'title') orderBy.title = order;
      else if (sortBy === 'duration') orderBy.duration = order;
      else if (sortBy === 'plays') orderBy.playCount = order;

      const page = Number(query.page) || 1;
      const limit = Number(query.limit) || 50;
      const skip = (page - 1) * limit;

      const [dbTracks, totalCount] = await Promise.all([
        (prisma as any).musicTrack.findMany({
          where: whereClause,
          orderBy,
          skip,
          take: limit,
        }),
        (prisma as any).musicTrack.count({ where: whereClause }),
      ]);

      if (dbTracks && dbTracks.length > 0) {
        const mapped = dbTracks.map((t: any) => ({
          ...t,
          uploadedAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
        }));
        return { tracks: mapped, total: totalCount };
      }
    } catch (err) {
      console.warn('PostgreSQL Prisma search query skipped or failed, using in-memory catalog store:', err);
    }

    // Fallback to in-memory store
    let filtered = [...inMemoryCatalog];

    if (query.category && query.category !== 'All') {
      filtered = filtered.filter((t) => t.category.toLowerCase() === query.category?.toLowerCase());
    }
    if (query.language && query.language !== 'All') {
      filtered = filtered.filter((t) => t.language.toLowerCase() === query.language?.toLowerCase());
    }
    if (query.isActive !== undefined && query.isActive !== 'all') {
      const activeBool = query.isActive === 'true';
      filtered = filtered.filter((t) => t.isActive === activeBool);
    }
    if (query.isPremium !== undefined && query.isPremium !== 'all') {
      const premBool = query.isPremium === 'true';
      filtered = filtered.filter((t) => t.isPremium === premBool);
    }
    if (query.search) {
      const s = query.search.toLowerCase();
      filtered = filtered.filter(
        (t) =>
          t.title.toLowerCase().includes(s) ||
          t.artist.toLowerCase().includes(s) ||
          t.category.toLowerCase().includes(s)
      );
    }

    const sortBy = query.sortBy || 'newest';
    filtered.sort((a, b) => {
      if (sortBy === 'title') return a.title.localeCompare(b.title);
      if (sortBy === 'duration') return b.duration - a.duration;
      if (sortBy === 'plays') return b.playCount - a.playCount;
      if (sortBy === 'oldest') return new Date(a.uploadedAt).getTime() - new Date(b.uploadedAt).getTime();
      return new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime();
    });

    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 50;
    const start = (page - 1) * limit;
    const paginated = filtered.slice(start, start + limit);

    return { tracks: paginated, total: filtered.length };
  }

  // 2. Fetch System Statistics
  async getMusicStats(): Promise<MusicStatsResponse> {
    const { tracks } = await this.getMusicCatalog({ limit: 1000 });

    const totalSongs = tracks.length;
    const totalStorageBytes = tracks.reduce((acc, t) => acc + (t.fileSize || 0), 0);
    const totalPlays = tracks.reduce((acc, t) => acc + (t.playCount || 0), 0);

    const categoryBreakdown: Record<string, number> = {};
    const languageBreakdown: Record<string, number> = {};

    tracks.forEach((t) => {
      categoryBreakdown[t.category] = (categoryBreakdown[t.category] || 0) + 1;
      languageBreakdown[t.language] = (languageBreakdown[t.language] || 0) + 1;
    });

    return {
      totalSongs,
      totalStorageBytes,
      totalCategoriesCount: Object.keys(categoryBreakdown).length,
      totalPlays,
      categoryBreakdown,
      languageBreakdown,
    };
  }

  // 3. Pre-upload Duplicate Check
  async checkDuplicates(req: DuplicateCheckRequest): Promise<DuplicateCheckResponse> {
    const { tracks } = await this.getMusicCatalog({ limit: 2000 });
    const duplicates: DuplicateCheckResponse['duplicates'] = [];

    for (const f of req.files) {
      if (f.hash) {
        const matchHash = tracks.find((t) => t.fileHash === f.hash);
        if (matchHash) {
          duplicates.push({
            fileName: f.fileName,
            existingId: matchHash.id,
            existingTitle: matchHash.title,
            matchType: 'hash',
          });
          continue;
        }
      }

      const normName = f.fileName.trim().toLowerCase();
      const matchName = tracks.find((t) => {
        const cleanT = t.title.toLowerCase();
        return normName.includes(cleanT) || cleanT.includes(normName);
      });

      if (matchName) {
        duplicates.push({
          fileName: f.fileName,
          existingId: matchName.id,
          existingTitle: matchName.title,
          matchType: 'filename',
        });
      }
    }

    return { duplicates };
  }

  // 4. Automatic Folder Category Detection & Cleanup
  detectCategoryFromPath(filePath: string, defaultCategory: string = 'Lullabies'): string {
    const normalized = filePath.replace(/\\/g, '/');
    const parts = normalized.split('/').filter(Boolean);

    // Standard known category mapping
    const categoriesMap: Record<string, string> = {
      lullaby: 'Lullabies',
      lullabies: 'Lullabies',
      whitenoise: 'White Noise',
      'white noise': 'White Noise',
      noise: 'White Noise',
      nature: 'Nature Sounds',
      'nature sounds': 'Nature Sounds',
      rain: 'Nature Sounds',
      womb: 'Womb Sounds',
      'womb sounds': 'Womb Sounds',
      heartbeat: 'Womb Sounds',
      instrumental: 'Instrumental',
      piano: 'Instrumental',
      rhymes: 'Nursery Rhymes',
      'nursery rhymes': 'Nursery Rhymes',
      regional: 'Regional',
      lori: 'Regional',
      parent: 'Parent Recordings',
      recordings: 'Parent Recordings',
      voice: 'Parent Recordings',
    };

    for (let i = parts.length - 2; i >= 0; i--) {
      const segment = parts[i].toLowerCase().trim();
      for (const [key, catName] of Object.entries(categoriesMap)) {
        if (segment.includes(key)) {
          return catName;
        }
      }
      // If folder is named nicely e.g. "Bedtime Chimes", capitalize it
      if (segment.length > 2 && !['music', 'audio', 'songs', 'uploads', 'files'].includes(segment)) {
        return segment
          .split(' ')
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
          .join(' ');
      }
    }

    return defaultCategory;
  }

  // 5. Clean Title from File Name
  cleanTitleFromFilename(filename: string): string {
    const basename = path.basename(filename, path.extname(filename));
    const cleaned = basename
      .replace(/^[\d\s_\-\.]+/, '') // remove leading numbers like "01 - " or "01_"
      .replace(/[_\-]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    if (!cleaned) return basename;
    return cleaned
      .split(' ')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  }

  // 6. Process Bulk Audio Files & Metadata Insertion
  async processBulkUpload(
    files: Array<{
      originalname: string;
      buffer: Buffer;
      size: number;
      mimetype?: string;
      relativePath?: string;
    }>,
    overrideCategory?: string,
    overrideLanguage?: string
  ): Promise<UploadBatchStatus> {
    const jobId = `job_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const totalFiles = files.length;

    const jobStatus: UploadBatchStatus = {
      jobId,
      status: 'processing',
      totalFiles,
      successCount: 0,
      failedCount: 0,
      processedFiles: 0,
      percentage: 0,
      details: [],
    };

    jobStore.set(jobId, jobStatus);

    // Process asynchronously in background
    setImmediate(async () => {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const relPath = file.relativePath || file.originalname;

        try {
          // Format validation
          const ext = path.extname(file.originalname).toLowerCase().replace('.', '');
          const allowedFormats = ['mp3', 'wav', 'aac', 'm4a', 'ogg'];
          if (!allowedFormats.includes(ext)) {
            throw new Error(`Unsupported audio format '.${ext}'. Allowed: ${allowedFormats.join(', ')}`);
          }

          if (file.size === 0) {
            throw new Error('Corrupted or empty file (0 bytes)');
          }

          // Generate file hash for duplicate prevention
          const hash = crypto.createHash('sha256').update(file.buffer).digest('hex');

          // Auto category detection from path if not overridden
          const detectedCategory = overrideCategory && overrideCategory !== 'Auto-Detect'
            ? overrideCategory
            : this.detectCategoryFromPath(relPath);

          const title = this.cleanTitleFromFilename(file.originalname);

          // Save file to disk
          const safeFilename = `${Date.now()}_${crypto.randomBytes(4).toString('hex')}_${file.originalname.replace(/[^a-zA-Z0-9\._\-]/g, '_')}`;
          const diskPath = path.join(UPLOAD_DIR, safeFilename);
          await fs.promises.writeFile(diskPath, file.buffer);

          const publicStorageUrl = `/uploads/music/${safeFilename}`;

          // Rough metadata estimation (for real duration, fallback to estimate based on file size)
          // Average 320kbps MP3 = ~40KB per second
          const estimatedDuration = Math.max(30, Math.round(file.size / (40 * 1024)));

          const newTrack: MusicTrackItem = {
            id: `tr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
            title,
            category: detectedCategory,
            language: overrideLanguage || 'English',
            duration: estimatedDuration,
            fileSize: file.size,
            audioFormat: ext,
            bitrate: 320,
            artist: 'Maatriva Sound Studio',
            album: 'Nursery Audio Collection',
            storageUrl: publicStorageUrl,
            fileHash: hash,
            thumbnail: this.getCategoryThumbnail(detectedCategory),
            uploadedAt: new Date().toISOString(),
            isPremium: false,
            isActive: true,
            playCount: 0,
            favouriteCount: 0,
            targetAgeGroup: '0-24 Months',
            tags: [detectedCategory.toLowerCase(), ext],
          };

          // Save to Prisma Database if connection active
          try {
            await (prisma as any).musicTrack.create({
              data: {
                id: newTrack.id,
                title: newTrack.title,
                category: newTrack.category,
                language: newTrack.language,
                duration: newTrack.duration,
                fileSize: newTrack.fileSize,
                audioFormat: newTrack.audioFormat,
                bitrate: newTrack.bitrate,
                artist: newTrack.artist,
                album: newTrack.album,
                storageUrl: newTrack.storageUrl,
                fileHash: newTrack.fileHash,
                thumbnail: newTrack.thumbnail,
                isPremium: newTrack.isPremium,
                isActive: newTrack.isActive,
                playCount: 0,
                favouriteCount: 0,
                targetAgeGroup: newTrack.targetAgeGroup,
                tags: newTrack.tags,
              },
            });
          } catch (dbErr) {
            console.warn('Database save warning, persisting to in-memory store:', dbErr);
          }

          inMemoryCatalog.unshift(newTrack);

          jobStatus.successCount++;
          jobStatus.details.push({
            fileName: file.originalname,
            status: 'success',
            trackId: newTrack.id,
            category: newTrack.category,
          });
        } catch (err: any) {
          jobStatus.failedCount++;
          jobStatus.details.push({
            fileName: file.originalname,
            status: 'failed',
            error: err.message || 'Unknown processing error',
          });
        }

        jobStatus.processedFiles = i + 1;
        jobStatus.percentage = Math.round(((i + 1) / totalFiles) * 100);
      }

      jobStatus.status = jobStatus.failedCount === 0 ? 'completed' : (jobStatus.successCount === 0 ? 'failed' : 'partial');
    });

    return jobStatus;
  }

  // Helper for category thumbnails
  getCategoryThumbnail(category: string): string {
    const thumbnails: Record<string, string> = {
      'Lullabies': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=300&q=80',
      'White Noise': 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=300&q=80',
      'Nature Sounds': 'https://images.unsplash.com/photo-1511497584788-876761c119ef?auto=format&fit=crop&w=300&q=80',
      'Womb Sounds': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?auto=format&fit=crop&w=300&q=80',
      'Instrumental': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=300&q=80',
      'Nursery Rhymes': 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=300&q=80',
      'Regional': 'https://images.unsplash.com/photo-1532767153582-b1a0e5145009?auto=format&fit=crop&w=300&q=80',
      'Parent Recordings': 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?auto=format&fit=crop&w=300&q=80',
    };
    return thumbnails[category] || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80';
  }

  // 7. Get Job Status
  getJobStatus(jobId: string): UploadBatchStatus | undefined {
    return jobStore.get(jobId);
  }

  // 8. Execute Batch Operations (Delete, Category, Language, Status, Export CSV)
  async executeBatchOperation(payload: BatchOperationPayload): Promise<{ success: boolean; affectedCount: number; message: string; csvContent?: string }> {
    const { action, trackIds, data } = payload;
    let affectedCount = 0;

    if (action === 'delete') {
      try {
        await (prisma as any).musicTrack.deleteMany({
          where: { id: { in: trackIds } },
        });
      } catch (err) {
        console.warn('Prisma deleteMany warning:', err);
      }
      inMemoryCatalog = inMemoryCatalog.filter((t) => !trackIds.includes(t.id));
      affectedCount = trackIds.length;
      return { success: true, affectedCount, message: `Successfully deleted ${affectedCount} tracks.` };
    }

    if (action === 'update_category' && data?.category) {
      try {
        await (prisma as any).musicTrack.updateMany({
          where: { id: { in: trackIds } },
          data: { category: data.category },
        });
      } catch (err) {
        console.warn('Prisma updateMany category warning:', err);
      }
      inMemoryCatalog = inMemoryCatalog.map((t) => (trackIds.includes(t.id) ? { ...t, category: data.category! } : t));
      affectedCount = trackIds.length;
      return { success: true, affectedCount, message: `Updated category to "${data.category}" for ${affectedCount} tracks.` };
    }

    if (action === 'update_language' && data?.language) {
      try {
        await (prisma as any).musicTrack.updateMany({
          where: { id: { in: trackIds } },
          data: { language: data.language },
        });
      } catch (err) {
        console.warn('Prisma updateMany language warning:', err);
      }
      inMemoryCatalog = inMemoryCatalog.map((t) => (trackIds.includes(t.id) ? { ...t, language: data.language! } : t));
      affectedCount = trackIds.length;
      return { success: true, affectedCount, message: `Updated language to "${data.language}" for ${affectedCount} tracks.` };
    }

    if (action === 'toggle_active' && data?.isActive !== undefined) {
      try {
        await (prisma as any).musicTrack.updateMany({
          where: { id: { in: trackIds } },
          data: { isActive: data.isActive },
        });
      } catch (err) {
        console.warn('Prisma updateMany status warning:', err);
      }
      inMemoryCatalog = inMemoryCatalog.map((t) => (trackIds.includes(t.id) ? { ...t, isActive: data.isActive! } : t));
      affectedCount = trackIds.length;
      return { success: true, affectedCount, message: `Updated active status for ${affectedCount} tracks.` };
    }

    if (action === 'toggle_premium' && data?.isPremium !== undefined) {
      try {
        await (prisma as any).musicTrack.updateMany({
          where: { id: { in: trackIds } },
          data: { isPremium: data.isPremium },
        });
      } catch (err) {
        console.warn('Prisma updateMany premium warning:', err);
      }
      inMemoryCatalog = inMemoryCatalog.map((t) => (trackIds.includes(t.id) ? { ...t, isPremium: data.isPremium! } : t));
      affectedCount = trackIds.length;
      return { success: true, affectedCount, message: `Updated premium status for ${affectedCount} tracks.` };
    }

    if (action === 'export_metadata') {
      const selected = inMemoryCatalog.filter((t) => trackIds.includes(t.id));
      const headers = ['ID', 'Title', 'Category', 'Language', 'Duration (s)', 'File Size (Bytes)', 'Format', 'Artist', 'Storage URL', 'Uploaded At', 'Is Active', 'Is Premium'];
      const rows = selected.map((t) => [
        t.id,
        `"${t.title.replace(/"/g, '""')}"`,
        `"${t.category}"`,
        `"${t.language}"`,
        t.duration,
        t.fileSize,
        t.audioFormat,
        `"${t.artist}"`,
        `"${t.storageUrl}"`,
        t.uploadedAt,
        t.isActive,
        t.isPremium,
      ]);

      const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
      return {
        success: true,
        affectedCount: selected.length,
        message: `Exported metadata for ${selected.length} tracks.`,
        csvContent,
      };
    }

    return { success: false, affectedCount: 0, message: 'Invalid batch action or payload.' };
  }

  // 9. Single Track Edit & Delete
  async updateTrack(id: string, updates: Partial<MusicTrackItem>): Promise<MusicTrackItem | null> {
    try {
      const updated = await (prisma as any).musicTrack.update({
        where: { id },
        data: updates,
      });
      if (updated) {
        inMemoryCatalog = inMemoryCatalog.map((t) => (t.id === id ? { ...t, ...updates } : t));
        return { ...updated, uploadedAt: new Date(updated.uploadedAt).toISOString() };
      }
    } catch (err) {
      console.warn('Update track DB warning, updating memory:', err);
    }

    const index = inMemoryCatalog.findIndex((t) => t.id === id);
    if (index !== -1) {
      inMemoryCatalog[index] = { ...inMemoryCatalog[index], ...updates };
      return inMemoryCatalog[index];
    }
    return null;
  }

  async deleteTrack(id: string): Promise<boolean> {
    try {
      await (prisma as any).musicTrack.delete({ where: { id } });
    } catch (err) {
      console.warn('Delete track DB warning:', err);
    }
    const initialLen = inMemoryCatalog.length;
    inMemoryCatalog = inMemoryCatalog.filter((t) => t.id !== id);
    return inMemoryCatalog.length < initialLen;
  }
}
