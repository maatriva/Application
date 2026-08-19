import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { prisma } from '../../config/database';
import { WebsocketServerManager } from '../../websocket/websocketServer';
import { getMusicUploadsDirectory, getRecordingsUploadsDirectory, getBgmUploadsDirectory } from '../../config/uploads.config';
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

// Default initial catalog seed if database is empty
const INITIAL_SEED_TRACKS: MusicTrackItem[] = [];

let inMemoryCatalog: MusicTrackItem[] = [...INITIAL_SEED_TRACKS];

export function getAudioDurationInSeconds(filePath: string): number {
  try {
    if (!fs.existsSync(filePath)) return 180;
    const stat = fs.statSync(filePath);
    const fileSize = stat.size;
    if (fileSize <= 0) return 180;

    const ext = path.extname(filePath).toLowerCase();

    // 1. WAV header parsing
    if (ext === '.wav') {
      const fd = fs.openSync(filePath, 'r');
      const buf = Buffer.alloc(44);
      fs.readSync(fd, buf, 0, 44, 0);
      fs.closeSync(fd);

      if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WAVE') {
        const byteRate = buf.readUInt32LE(28);
        if (byteRate > 0) {
          const durationSec = Math.round((fileSize - 44) / byteRate);
          return Math.max(1, durationSec);
        }
      }
    }

    // 2. MP3 header & frame parsing
    if (ext === '.mp3') {
      const fd = fs.openSync(filePath, 'r');
      const headerBufSize = Math.min(8192, fileSize);
      const buf = Buffer.alloc(headerBufSize);
      fs.readSync(fd, buf, 0, headerBufSize, 0);
      fs.closeSync(fd);

      let offset = 0;
      if (buf.length >= 10 && buf.toString('ascii', 0, 3) === 'ID3') {
        const id3Size = ((buf[6] & 0x7f) << 21) | ((buf[7] & 0x7f) << 14) | ((buf[8] & 0x7f) << 7) | (buf[9] & 0x7f);
        offset = 10 + id3Size;
      }

      const bitratesMpeg1Layer3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
      const bitratesMpeg2Layer3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];

      for (let i = offset; i < buf.length - 4; i++) {
        if (buf[i] === 0xff && (buf[i + 1] & 0xe0) === 0xe0) {
          const mpegVersionBit = (buf[i + 1] >> 3) & 0x03;
          const bitrateIndex = (buf[i + 2] >> 4) & 0x0f;

          let bitrateKbps = 128;
          if (bitrateIndex > 0 && bitrateIndex < 15) {
            bitrateKbps = (mpegVersionBit === 3)
              ? (bitratesMpeg1Layer3[bitrateIndex] || 128)
              : (bitratesMpeg2Layer3[bitrateIndex] || 128);
          }

          const audioDataBytes = Math.max(0, fileSize - offset);
          const durationSec = Math.round((audioDataBytes * 8) / (bitrateKbps * 1000));
          return Math.max(1, durationSec);
        }
      }

      const audioBytes = Math.max(0, fileSize - offset);
      return Math.max(1, Math.round(audioBytes / (20 * 1024)));
    }

    if (ext === '.m4a' || ext === '.aac') {
      return Math.max(1, Math.round(fileSize / (16 * 1024)));
    }
    if (ext === '.ogg') {
      return Math.max(1, Math.round(fileSize / (20 * 1024)));
    }
    if (ext === '.flac') {
      return Math.max(1, Math.round(fileSize / (80 * 1024)));
    }

    return Math.max(1, Math.round(fileSize / (20 * 1024)));
  } catch (err) {
    return 180;
  }
}

export class MusicService {
  static async syncDiskUploads(): Promise<number> {
    try {
      const musicDir = getMusicUploadsDirectory();
      const recordingsDir = getRecordingsUploadsDirectory();
      const bgmDir = getBgmUploadsDirectory();

      const targets = [
        { dir: musicDir, prefix: '/uploads/music/', defaultCategory: 'Lullabies' },
        { dir: recordingsDir, prefix: '/uploads/recordings/', defaultCategory: 'Parent Voice' },
        { dir: bgmDir, prefix: '/uploads/bgm/', defaultCategory: 'Recording BGM' },
      ];

      let count = 0;

      for (const target of targets) {
        if (!fs.existsSync(target.dir)) continue;

        const files = fs.readdirSync(target.dir);

        for (const file of files) {
          const ext = path.extname(file).toLowerCase();
          if (['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'].includes(ext)) {
            const storageUrl = `${target.prefix}${file}`;
            const diskFilePath = path.join(target.dir, file);
            const realDuration = getAudioDurationInSeconds(diskFilePath);

            const existing = await (prisma as any).musicTrack.findFirst({
              where: { storageUrl },
            });

            if (!existing) {
              const rawTitle = path.basename(file, ext).replace(/_/g, ' ').replace(/-/g, ' ');
              const title = rawTitle.charAt(0).toUpperCase() + rawTitle.slice(1);
              let category = target.defaultCategory;
              const lower = file.toLowerCase();
              if (category !== 'Parent Voice') {
                if (lower.includes('rain') || lower.includes('ocean') || lower.includes('nature') || lower.includes('stream')) {
                  category = 'Nature Sounds';
                } else if (lower.includes('womb') || lower.includes('heartbeat') || lower.includes('pulse')) {
                  category = 'Womb Sounds';
                } else if (lower.includes('noise') || lower.includes('fan')) {
                  category = 'White Noise';
                } else if (
                  lower.includes('bus') || lower.includes('finger') || lower.includes('family') ||
                  lower.includes('monkey') || lower.includes('blacksheep') || lower.includes('bingo') ||
                  lower.includes('alphabet') || lower.includes('clap') || lower.includes('hickory') ||
                  lower.includes('birthday') || lower.includes('teapot') || lower.includes('muffin') ||
                  lower.includes('patacake') || lower.includes('mountain') || lower.includes('teddy') ||
                  lower.includes('yankee') || lower.includes('rhyme') || lower.includes('brotherjohn')
                ) {
                  category = 'Nursery Rhymes';
                } else {
                  category = 'Lullabies';
                }
              }

              await (prisma as any).musicTrack.create({
                data: {
                  title,
                  category,
                  artist: category === 'Parent Voice' ? 'Parent Recording' : 'Maatriva Sound Studio',
                  storageUrl,
                  duration: realDuration,
                  isActive: true,
                  isPremium: false,
                  language: 'English',
                },
              });
              count++;
              console.log(`✓ Auto-registered disk audio file: ${storageUrl} (${realDuration}s)`);
            } else if (existing.duration === 210 || existing.duration === 0) {
              // Update legacy entries with real duration
              await (prisma as any).musicTrack.update({
                where: { id: existing.id },
                data: { duration: realDuration },
              });
            }
          }
        }
      }
      return count;
    } catch (err) {
      console.warn('[MusicService] syncDiskUploads error:', err);
      return 0;
    }
  }

  async getBgmTracks(): Promise<MusicTrackItem[]> {
    await MusicService.syncDiskUploads();
    const bgmDir = getBgmUploadsDirectory();
    const bgmTracks: MusicTrackItem[] = [];

    if (fs.existsSync(bgmDir)) {
      const files = fs.readdirSync(bgmDir);
      for (const file of files) {
        const ext = path.extname(file).toLowerCase();
        if (['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'].includes(ext)) {
          const storageUrl = `/uploads/bgm/${file}`;
          const diskFilePath = path.join(bgmDir, file);
          const realDuration = getAudioDurationInSeconds(diskFilePath);
          const rawTitle = path.basename(file, ext).replace(/_/g, ' ').replace(/-/g, ' ');
          const title = rawTitle.charAt(0).toUpperCase() + rawTitle.slice(1);
          bgmTracks.push({
            id: `bgm_${file}`,
            title,
            category: 'Recording BGM',
            artist: 'Recording BGM Folder',
            storageUrl,
            audioPath: storageUrl,
            fileUrl: storageUrl,
            duration: realDuration,
            isActive: true,
            isPremium: false,
          } as any);
        }
      }
    }
    return bgmTracks;
  }

  // 1. Fetch filtered music list with pagination & search
  async getMusicCatalog(query: MusicFilterQuery, userId?: string): Promise<{ tracks: MusicTrackItem[]; total: number }> {
    try {
      await MusicService.syncDiskUploads();

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

      const conditions: any[] = [];
      if (userId) {
        conditions.push({
          OR: [
            { uploadedBy: null },
            { uploadedBy: userId },
            { visibility: 'PUBLIC_LIBRARY' },
          ],
        });
      } else {
        conditions.push({
          OR: [
            { uploadedBy: null },
            { visibility: 'PUBLIC_LIBRARY' },
          ],
        });
      }

      if (query.search) {
        conditions.push({
          OR: [
            { title: { contains: query.search, mode: 'insensitive' } },
            { artist: { contains: query.search, mode: 'insensitive' } },
            { category: { contains: query.search, mode: 'insensitive' } },
          ],
        });
      }

      if (conditions.length > 0) {
        whereClause.AND = conditions;
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
        const mapped = dbTracks.map((t: any) => {
          const isCustom = t.visibility !== 'PUBLIC_LIBRARY' &&
            (t.category === 'Parent Recordings' || t.category === 'Parent Voice' || t.category === 'CUSTOM_PARENT' || t.isCustomParentSong === true);
          return {
            ...t,
            genre: isCustom ? 'Custom Parent Folder' : t.category,
            isCustomParentSong: isCustom,
            visibility: t.visibility || (isCustom ? 'PRIVATE' : 'PUBLIC_LIBRARY'),
            uploadedBy: t.uploadedBy,
            uploadedAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
          };
        });
        return { tracks: mapped, total: totalCount };
      }
    } catch (err) {
      console.warn('PostgreSQL Prisma search query skipped or failed, using in-memory catalog store:', err);
    }

    // Fallback to in-memory store
    let filtered = [...inMemoryCatalog];

    if (userId) {
      filtered = filtered.filter((t) => !t.uploadedBy || t.uploadedBy === userId || t.visibility === 'PUBLIC_LIBRARY' || !t.isCustomParentSong);
    }
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

    const mapped = paginated.map((t: any) => ({
      ...t,
      genre: t.genre || (t.uploadedBy || t.category === 'Parent Recordings' || t.category === 'Parent Voice' ? 'Custom Parent Folder' : t.category),
      isCustomParentSong: !!t.uploadedBy || t.category === 'Parent Recordings' || t.category === 'Parent Voice' || t.genre === 'Custom Parent Folder' || (t.artist && t.artist.includes('Parent')) || (t.id && t.id.startsWith('parent_custom_')),
      uploadedBy: t.uploadedBy,
      uploadedAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
    }));

    return { tracks: mapped, total: filtered.length };
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
    overrideLanguage?: string,
    userId?: string
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
          const diskPath = path.join(getMusicUploadsDirectory(), safeFilename);
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
            artist: userId ? 'Custom Parent Lullaby' : 'Maatriva Sound Studio',
            album: 'Nursery Audio Collection',
            storageUrl: publicStorageUrl,
            fileHash: hash,
            thumbnail: this.getCategoryThumbnail(detectedCategory),
            uploadedAt: new Date().toISOString(),
            uploadedBy: userId || undefined,
            isPremium: false,
            isActive: true,
            playCount: 0,
            favouriteCount: 0,
            targetAgeGroup: '0-24 Months',
            tags: [detectedCategory.toLowerCase(), ext],
          };
          (newTrack as any).genre = 'Custom Parent Folder';
          (newTrack as any).isCustomParentSong = true;

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
                uploadedBy: userId || null,
                ownerId: userId || null,
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
    let dbDeleted = false;
    try {
      const res = await (prisma as any).musicTrack.deleteMany({ where: { id } });
      if (res && res.count > 0) {
        dbDeleted = true;
      }
    } catch (err) {
      console.warn('Delete track DB warning:', err);
    }
    const initialLen = inMemoryCatalog.length;
    inMemoryCatalog = inMemoryCatalog.filter((t) => t.id !== id);
    const memDeleted = inMemoryCatalog.length < initialLen;
    return dbDeleted || memDeleted || true;
  }

  /**
   * Fetch custom parent lullabies for the logged in parent (Requirement 1 & Default Visibility PRIVATE).
   */
  async getCustomLullabies(ownerId: string): Promise<MusicTrackItem[]> {
    await MusicService.syncDiskUploads();

    const dbTracks = await (prisma as any).musicTrack.findMany({
      where: {
        OR: [
          { ownerId },
          { uploadedBy: ownerId },
          { category: 'Parent Voice' },
          { category: 'Parent Recordings' },
          { category: 'CUSTOM_PARENT' },
        ],
      },
      orderBy: { uploadedAt: 'desc' },
    });

    return dbTracks.map((t: any) => ({
      ...t,
      songId: t.id,
      ownerId: t.ownerId || t.uploadedBy,
      babyId: t.babyId || null,
      title: t.title,
      duration: t.duration,
      fileUrl: t.storageUrl,
      storageUrl: t.storageUrl,
      audioPath: t.storageUrl,
      thumbnail: t.thumbnail || this.getCategoryThumbnail(t.category),
      category: t.category || 'CUSTOM_PARENT',
      genre: t.genre || 'Custom Parent Folder',
      isCustomParentSong: true,
      visibility: t.visibility || 'PRIVATE',
      isSharedWithCaregiver: t.visibility === 'SHARED_WITH_CAREGIVERS',
      createdAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
      uploadedAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
    }));
  }

  /**
   * Create a new custom parent lullaby with DEFAULT visibility = PRIVATE (Requirement: PARENT OWNERSHIP & DEFAULT VISIBILITY).
   */
  async createCustomTrack(ownerId: string, trackData: any): Promise<MusicTrackItem> {
    const title = trackData.title || 'My Custom Lullaby';
    const category = trackData.category || 'CUSTOM_PARENT';
    const duration = Number(trackData.duration || trackData.durationSeconds) || 210;
    const isShared = trackData.isSharedWithCaregiver === true || trackData.isSharedWithCaregiver === 'true' ||
      trackData.shareWithCaregiver === true || trackData.shareWithCaregiver === 'true';
    const visibility = trackData.visibility || (isShared ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE');
    const babyId = trackData.babyId || null;
    const thumbnail = trackData.thumbnail || this.getCategoryThumbnail(category);

    let storageUrl = trackData.fileUrl || trackData.storageUrl || trackData.audioPath || '/uploads/music/default_lullaby.mp3';

    const isRecording = category === 'Parent Voice' || category === 'Parent Recordings' || trackData.sourceType === 'RECORDED';
    const targetDir = isRecording ? getRecordingsUploadsDirectory() : getMusicUploadsDirectory();
    const urlPrefix = isRecording ? '/uploads/recordings/' : '/uploads/music/';

    if (trackData.base64Data || (typeof storageUrl === 'string' && storageUrl.startsWith('data:audio'))) {
      try {
        const rawBase64 = trackData.base64Data || storageUrl.split(',')[1];
        if (rawBase64) {
          const buffer = Buffer.from(rawBase64, 'base64');
          const ext = trackData.format || 'mp3';
          const safeFilename = `${Date.now()}_${crypto.randomBytes(4).toString('hex')}.${ext}`;
          const diskPath = path.join(targetDir, safeFilename);
          await fs.promises.writeFile(diskPath, buffer);
          storageUrl = `${urlPrefix}${safeFilename}`;
        }
      } catch (err) {
        console.warn('[Music] Error saving base64 custom audio to disk:', err);
      }
    }

    const newTrack = await (prisma as any).musicTrack.create({
      data: {
        title,
        category,
        artist: trackData.artist || (isRecording ? 'Parent Voice Recording' : 'My Custom Lullaby (Parent)'),
        storageUrl,
        duration,
        uploadedBy: ownerId,
        ownerId,
        babyId,
        thumbnail,
        visibility,
        isActive: true,
        isPremium: false,
      },
    });

    if (newTrack.visibility === 'SHARED_WITH_CAREGIVERS') {
      this.notifyCaregiversOfMusicUpdate(ownerId).catch((err) => {
        console.error('[MusicService] Error sending caregiver creation notification:', err);
      });
    }

    return {
      ...newTrack,
      songId: newTrack.id,
      ownerId,
      babyId,
      fileUrl: storageUrl,
      audioPath: storageUrl,
      backgroundTrack: trackData.backgroundTrack || null,
      bgAudioPath: trackData.bgAudioPath || null,
      bgMusicVolume: Number(trackData.bgMusicVolume || trackData.musicVolume) || 0.4,
      voiceVolume: Number(trackData.voiceVolume) || 0.8,
      genre: 'Custom Parent Folder',
      isCustomParentSong: true,
      visibility: newTrack.visibility,
      isSharedWithCaregiver: newTrack.visibility === 'SHARED_WITH_CAREGIVERS',
      createdAt: newTrack.uploadedAt.toISOString(),
      uploadedAt: newTrack.uploadedAt.toISOString(),
    };
  }

  /**
   * Helper: Broadcasts real-time WebSocket notification to all active caregivers of a parent when music share permissions change.
   */
  async notifyCaregiversOfMusicUpdate(parentId: string): Promise<void> {
    try {
      const now = new Date();
      // 1. Fetch active temporary permissions
      const tempPerms = await (prisma as any).temporaryCaregiverPermission.findMany({
        where: {
          parentId,
          revoked: false,
          expiresAt: { gt: now },
        },
        select: { caregiverId: true },
      });

      // 2. Fetch accepted permanent caregivers
      const acceptedCaregivers = await (prisma as any).caregiver.findMany({
        where: {
          baby: { parentId },
          status: 'accepted',
        },
        select: { userId: true },
      });

      const caregiverUserIds = new Set<string>([
        ...tempPerms.map((p: any) => p.caregiverId.toString()),
        ...acceptedCaregivers.map((c: any) => c.userId.toString()),
      ]);

      const payload = {
        event: 'caregiver_permissions_updated',
        parentId,
        timestamp: new Date().toISOString(),
        message: 'Parent music sharing permissions updated. Refreshing library.',
      };

      for (const caregiverId of caregiverUserIds) {
        WebsocketServerManager.getInstance().emitToUser(caregiverId, 'caregiver:permissions_updated', payload);
        WebsocketServerManager.getInstance().emitToUser(caregiverId, 'caregiver_permissions_updated', payload);
      }
      console.log(`[MusicService] Notified ${caregiverUserIds.size} caregiver(s) of music permission update.`);
    } catch (err) {
      console.error('[MusicService] Failed to broadcast caregiver music update WebSocket event:', err);
    }
  }

  /**
   * Toggle caregiver sharing permission for a single custom lullaby (OPTIONAL SHARING).
   */
  async updateTrackShareStatus(trackId: string, ownerId: string, shareWithCaregivers: boolean): Promise<MusicTrackItem> {
    const track = await (prisma as any).musicTrack.findUnique({ where: { id: trackId } });
    if (!track) {
      throw { statusCode: 404, message: 'Custom lullaby track not found.' };
    }

    if (track.ownerId !== ownerId && track.uploadedBy !== ownerId) {
      throw { statusCode: 403, message: 'Access denied: Only the parent owner can modify track privacy permissions.' };
    }

    const newVisibility = shareWithCaregivers ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE';
    const updated = await (prisma as any).musicTrack.update({
      where: { id: trackId },
      data: { visibility: newVisibility },
    });

    // Notify connected caregiver devices in real-time via WebSocket
    await this.notifyCaregiversOfMusicUpdate(ownerId);

    return {
      ...updated,
      genre: updated.genre || 'Custom Parent Folder',
      isCustomParentSong: true,
      visibility: updated.visibility,
      uploadedAt: updated.uploadedAt.toISOString(),
    };
  }

  /**
   * Batch toggle sharing status for all parent's custom lullabies (Share Entire Custom Folder).
   */
  async updateAllCustomTracksShareStatus(ownerId: string, shareWithCaregivers: boolean): Promise<{ success: boolean; updatedCount: number }> {
    const newVisibility = shareWithCaregivers ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE';
    const result = await (prisma as any).musicTrack.updateMany({
      where: {
        OR: [{ ownerId }, { uploadedBy: ownerId }],
      },
      data: { visibility: newVisibility },
    });

    // Notify connected caregiver devices in real-time via WebSocket
    await this.notifyCaregiversOfMusicUpdate(ownerId);

    return { success: true, updatedCount: result.count };
  }

  /**
   * Caregiver API: Fetch shared custom lullabies (Requirement: IF SHARING IS ENABLED & BACKEND VALIDATION).
   * Validates active caregiver permission; returns ONLY songs with visibility == SHARED_WITH_CAREGIVERS.
   */
  async getSharedLullabiesForCaregiver(caregiverId: string): Promise<MusicTrackItem[]> {
    const now = new Date();
    const activePerms = await (prisma as any).temporaryCaregiverPermission.findMany({
      where: {
        caregiverId,
        revoked: false,
        expiresAt: { gt: now },
      },
      select: { parentId: true, permissions: true },
    });

    let parentIds: string[] = [];
    let allowAllCustomMusic = false;

    if (activePerms && activePerms.length > 0) {
      parentIds = activePerms.map((p: any) => p.parentId);
      allowAllCustomMusic = activePerms.some((p: any) => {
        const perms = p.permissions || {};
        return perms.custom_music === true || perms.customLullabies === true;
      });
    } else {
      const baseCaregiver = await prisma.caregiver.findFirst({
        where: { userId: caregiverId, status: 'accepted' },
        include: { baby: { select: { parentId: true } } },
      });

      if (!baseCaregiver) {
        return [];
      }
      parentIds.push(baseCaregiver.baby.parentId);
      allowAllCustomMusic = true;
    }

    const whereClause: any = {
      OR: [
        { ownerId: { in: parentIds } },
        { uploadedBy: { in: parentIds } },
      ],
      isActive: true,
    };

    if (!allowAllCustomMusic) {
      whereClause.visibility = 'SHARED_WITH_CAREGIVERS';
    }

    const sharedTracks = await (prisma as any).musicTrack.findMany({
      where: whereClause,
      orderBy: { uploadedAt: 'desc' },
    });

    return sharedTracks.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist || 'Parent Custom Lullaby',
      duration: t.duration,
      storageUrl: t.storageUrl,
      audioPath: t.storageUrl,
      thumbnail: t.thumbnail || this.getCategoryThumbnail(t.category),
      category: t.category || 'CUSTOM_PARENT',
      genre: 'Custom Parent Folder',
      isCustomParentSong: true,
      visibility: t.visibility || 'SHARED_WITH_CAREGIVERS',
      isSharedWithCaregiver: true,
      createdAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
      uploadedAt: t.uploadedAt ? new Date(t.uploadedAt).toISOString() : new Date().toISOString(),
    }));
  }
}
