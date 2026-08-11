import path from 'path';
import fs from 'fs';

export function getUploadsDirectory(): string {
  const candidatePaths = [
    path.resolve(process.cwd(), 'uploads'),
    path.resolve(process.cwd(), 'backend', 'uploads'),
    path.resolve(__dirname, '../uploads'),
    path.resolve(__dirname, '../../uploads'),
    path.resolve(__dirname, '../../../uploads'),
  ];

  for (const candidate of candidatePaths) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  // Fallback default
  const defaultPath = process.cwd().endsWith('backend')
    ? path.resolve(process.cwd(), 'uploads')
    : path.resolve(process.cwd(), 'backend', 'uploads');

  if (!fs.existsSync(defaultPath)) {
    fs.mkdirSync(defaultPath, { recursive: true });
  }

  return defaultPath;
}

export function getMusicUploadsDirectory(): string {
  const base = getUploadsDirectory();
  const musicDir = path.join(base, 'music');
  if (!fs.existsSync(musicDir)) {
    fs.mkdirSync(musicDir, { recursive: true });
  }
  return musicDir;
}

export function getRecordingsUploadsDirectory(): string {
  const base = getUploadsDirectory();
  const recordingsDir = path.join(base, 'recordings');
  if (!fs.existsSync(recordingsDir)) {
    fs.mkdirSync(recordingsDir, { recursive: true });
  }
  return recordingsDir;
}

export function getBgmUploadsDirectory(): string {
  const base = getUploadsDirectory();
  const bgmDir = path.join(base, 'bgm');
  if (!fs.existsSync(bgmDir)) {
    fs.mkdirSync(bgmDir, { recursive: true });
  }
  return bgmDir;
}
