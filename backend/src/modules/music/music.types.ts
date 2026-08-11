export interface MusicTrackItem {
  id: string;
  ownerId?: string;
  babyId?: string;
  title: string;
  category: string;
  language: string;
  duration: number; // in seconds
  fileSize: number; // in bytes
  audioFormat: string;
  bitrate?: number;
  artist: string;
  album?: string;
  storageUrl: string;
  fileHash?: string;
  thumbnail?: string;
  visibility?: 'PRIVATE' | 'SHARED_WITH_CAREGIVERS' | 'PUBLIC_LIBRARY' | string;
  isCustomParentSong?: boolean;
  isSharedWithCaregiver?: boolean;
  uploadedAt: string;
  uploadedBy?: string;
  isPremium: boolean;
  isActive: boolean;
  playCount: number;
  favouriteCount: number;
  targetAgeGroup?: string;
  tags: string[];
}

export interface DuplicateCheckRequest {
  files: Array<{
    fileName: string;
    fileSize?: number;
    hash?: string;
  }>;
}

export interface DuplicateCheckResponse {
  duplicates: Array<{
    fileName: string;
    existingId: string;
    existingTitle: string;
    matchType: 'hash' | 'filename';
  }>;
}

export interface BatchOperationPayload {
  action: 'delete' | 'update_category' | 'update_language' | 'toggle_active' | 'toggle_premium' | 'export_metadata';
  trackIds: string[];
  data?: {
    category?: string;
    language?: string;
    isActive?: boolean;
    isPremium?: boolean;
  };
}

export interface MusicFilterQuery {
  search?: string;
  category?: string;
  language?: string;
  isActive?: string;
  isPremium?: string;
  sortBy?: 'newest' | 'oldest' | 'title' | 'duration' | 'plays';
  sortOrder?: 'asc' | 'desc';
  page?: number;
  limit?: number;
  uploadedBy?: string;
}

export interface MusicStatsResponse {
  totalSongs: number;
  totalStorageBytes: number;
  totalCategoriesCount: number;
  totalPlays: number;
  categoryBreakdown: Record<string, number>;
  languageBreakdown: Record<string, number>;
}

export interface UploadBatchStatus {
  jobId: string;
  status: 'processing' | 'completed' | 'failed' | 'partial';
  totalFiles: number;
  successCount: number;
  failedCount: number;
  processedFiles: number;
  percentage: number;
  details: Array<{
    fileName: string;
    status: 'success' | 'failed' | 'skipped';
    trackId?: string;
    category?: string;
    error?: string;
  }>;
}
