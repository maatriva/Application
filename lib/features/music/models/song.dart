class Song {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String category;    // specific sub-category (Lullabies, Rain Sounds, etc.)
  final String genre;       // broad genre label (Classic Lullabies, White Noise, etc.)
  final bool isFavorite;
  final String albumArtColor;
  final String audioPath;         // asset path, file URL, data URL, or local disk path
  final String sourceType;        // 'ASSET', 'UPLOADED', 'RECORDED'
  final DateTime? recentlyPlayedAt; // updated each time the song is played
  final bool isCustomParentSong;   // true if imported/custom parent music
  final bool isSharedWithCaregiver; // true if parent gave permission for caregiver to view/play
  final String visibility;        // 'PRIVATE', 'SHARED_WITH_CAREGIVERS', 'PUBLIC_LIBRARY'
  final String? ownerId;
  final String? babyId;            // Target baby ID for the recording
  final String? aiBadge;           // e.g. 'Recommended for Deep Sleep', 'Best for Crying', 'Sleeping Now'
  final int fileSize;              // File size in bytes
  final DateTime? createdAt;       // Creation timestamp

  // Audio Editor Metadata
  final String? voiceFileUrl;      // Raw original parent voice recording URL/path
  final String? mixedFileUrl;      // Final mixed/blended audio track URL/path
  final String? backgroundTrack;   // Selected ambient track name ('Soft Piano', 'White Noise', etc.)
  final String? bgAudioPath;       // Background audio track URL/path for blended voice recordings
  final double bgMusicVolume;      // Volume level for background music layer (0.0 to 1.0)
  final double voiceVolume;        // Volume level for recorded parent voice layer (0.0 to 1.0)
  final double trimStartSeconds;   // Audio trim start point in seconds
  final double? trimEndSeconds;    // Audio trim end point in seconds
  final String? introChime;        // Selected intro chime preset ('Music Box', 'Sweet Bell', 'Harp Prelude', 'None')
  final String? voicePreset;       // Voice tone filter preset ('Bedtime Warmth', 'Whisper Boost', 'Natural')
  final double fadeIn;             // Fade-in duration in seconds (0.0 to 5.0)
  final double fadeOut;            // Fade-out duration in seconds (0.0 to 5.0)
  final bool noiseReduction;       // Noise reduction filter toggle

  // STEP 2 Aliases & Schema Getters
  String get songId => id;
  String get type => category;
  String get fileUrl => audioPath;
  String get thumbnail => albumArtColor;
  double get musicVolume => bgMusicVolume;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.category,
    required this.genre,
    this.isFavorite = false,
    required this.albumArtColor,
    this.audioPath = '',
    this.sourceType = 'ASSET',
    this.recentlyPlayedAt,
    this.isCustomParentSong = false,
    this.isSharedWithCaregiver = false,
    this.visibility = 'PRIVATE',
    this.ownerId,
    this.babyId,
    this.aiBadge,
    this.fileSize = 0,
    this.createdAt,
    this.voiceFileUrl,
    this.mixedFileUrl,
    this.backgroundTrack,
    this.bgAudioPath,
    this.bgMusicVolume = 0.4,
    this.voiceVolume = 0.8,
    this.trimStartSeconds = 0.0,
    this.trimEndSeconds,
    this.introChime,
    this.voicePreset,
    this.fadeIn = 1.0,
    this.fadeOut = 1.0,
    this.noiseReduction = true,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    String? category,
    String? genre,
    bool? isFavorite,
    String? albumArtColor,
    String? audioPath,
    String? sourceType,
    DateTime? recentlyPlayedAt,
    bool clearRecentlyPlayedAt = false,
    bool? isCustomParentSong,
    bool? isSharedWithCaregiver,
    String? visibility,
    String? ownerId,
    String? babyId,
    String? aiBadge,
    int? fileSize,
    DateTime? createdAt,
    String? voiceFileUrl,
    String? mixedFileUrl,
    String? backgroundTrack,
    String? bgAudioPath,
    double? bgMusicVolume,
    double? voiceVolume,
    double? trimStartSeconds,
    double? trimEndSeconds,
    String? introChime,
    String? voicePreset,
    double? fadeIn,
    double? fadeOut,
    bool? noiseReduction,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      albumArtColor: albumArtColor ?? this.albumArtColor,
      audioPath: audioPath ?? this.audioPath,
      sourceType: sourceType ?? this.sourceType,
      recentlyPlayedAt: clearRecentlyPlayedAt
          ? null
          : (recentlyPlayedAt ?? this.recentlyPlayedAt),
      isCustomParentSong: isCustomParentSong ?? this.isCustomParentSong,
      isSharedWithCaregiver: isSharedWithCaregiver ?? this.isSharedWithCaregiver,
      visibility: visibility ?? this.visibility,
      ownerId: ownerId ?? this.ownerId,
      babyId: babyId ?? this.babyId,
      aiBadge: aiBadge ?? this.aiBadge,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      voiceFileUrl: voiceFileUrl ?? this.voiceFileUrl,
      mixedFileUrl: mixedFileUrl ?? this.mixedFileUrl,
      backgroundTrack: backgroundTrack ?? this.backgroundTrack,
      bgAudioPath: bgAudioPath ?? this.bgAudioPath,
      bgMusicVolume: bgMusicVolume ?? this.bgMusicVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      trimStartSeconds: trimStartSeconds ?? this.trimStartSeconds,
      trimEndSeconds: trimEndSeconds ?? this.trimEndSeconds,
      introChime: introChime ?? this.introChime,
      voicePreset: voicePreset ?? this.voicePreset,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
      noiseReduction: noiseReduction ?? this.noiseReduction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': id,
      'title': title,
      'artist': artist,
      'durationSeconds': duration.inSeconds,
      'duration': duration.inSeconds,
      'category': category,
      'type': category,
      'genre': genre,
      'isFavorite': isFavorite,
      'albumArtColor': albumArtColor,
      'thumbnail': albumArtColor,
      'audioPath': audioPath,
      'fileUrl': audioPath,
      'sourceType': sourceType,
      'isCustomParentSong': isCustomParentSong,
      'isSharedWithCaregiver': isSharedWithCaregiver || visibility == 'SHARED_WITH_CAREGIVERS',
      'visibility': visibility,
      'ownerId': ownerId,
      'babyId': babyId,
      'aiBadge': aiBadge,
      'fileSize': fileSize,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'voiceFileUrl': voiceFileUrl ?? audioPath,
      'mixedFileUrl': mixedFileUrl ?? audioPath,
      'backgroundTrack': backgroundTrack,
      'bgAudioPath': bgAudioPath,
      'bgMusicVolume': bgMusicVolume,
      'musicVolume': bgMusicVolume,
      'voiceVolume': voiceVolume,
      'trimStartSeconds': trimStartSeconds,
      'trimEndSeconds': trimEndSeconds,
      'introChime': introChime,
      'voicePreset': voicePreset,
      'fadeIn': fadeIn,
      'fadeOut': fadeOut,
      'noiseReduction': noiseReduction,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    final rawGenre = json['genre'] as String?;
    final rawCategory = json['category'] as String? ?? json['type'] as String? ?? 'Lullabies';
    final artistStr = json['artist'] as String? ?? '';
    final idStr = json['id'] as String? ?? json['songId'] as String? ?? '';
    final uploadedBy = json['uploadedBy'] as String? ?? json['ownerId'] as String?;
    final visibilityStr = json['visibility'] as String? ?? (json['isSharedWithCaregiver'] == true ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE');
    final audioPathVal = json['audioPath'] as String? ?? json['fileUrl'] as String? ?? json['storageUrl'] as String? ?? 'audio/lullaby_classic.wav';

    final bool isCustom = (json['isCustomParentSong'] as bool?) ??
        (rawGenre == "Parent's Melody Vault" ||
         rawGenre == 'Custom Parent Folder' ||
         rawGenre == 'Custom Parent Lullabies' ||
         rawCategory == 'Parent Voice' ||
         rawCategory == 'Parent Recordings' ||
         rawCategory == 'CUSTOM_PARENT' ||
         artistStr.toLowerCase().contains('custom parent') ||
         artistStr.toLowerCase().contains('my custom lullaby') ||
         idStr.startsWith('parent_custom_') ||
         idStr.startsWith('parent_recording_'));

    final genreStr = (rawGenre == 'Custom Parent Folder' || rawGenre == 'Custom Parent Lullabies')
        ? "Parent's Melody Vault"
        : (rawGenre ?? (isCustom ? "Parent's Melody Vault" : rawCategory));

    final rawSourceType = json['sourceType'] as String?;
    final String resolvedSourceType;
    if (rawSourceType != null && rawSourceType.isNotEmpty) {
      resolvedSourceType = rawSourceType.toUpperCase();
    } else if (rawCategory == 'Parent Voice' ||
        rawCategory == 'Parent Recordings' ||
        idStr.startsWith('parent_recording_') ||
        artistStr.toLowerCase().contains('parent voice') ||
        (json['aiBadge'] as String? ?? '').toLowerCase().contains('parent recording')) {
      resolvedSourceType = 'RECORDED';
    } else if (isCustom ||
        (uploadedBy != null && uploadedBy.isNotEmpty) ||
        idStr.startsWith('parent_custom_') ||
        json['fileUrl'] != null ||
        json['storageUrl'] != null ||
        audioPathVal.startsWith('/uploads/') ||
        audioPathVal.startsWith('http://') ||
        audioPathVal.startsWith('https://') ||
        audioPathVal.startsWith('data:') ||
        audioPathVal.startsWith('blob:')) {
      resolvedSourceType = 'UPLOADED';
    } else {
      resolvedSourceType = 'ASSET';
    }

    final createdAtStr = json['createdAt'] as String? ?? json['uploadedAt'] as String?;

    double parseDouble(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val is bool) return val ? 1.0 : 0.0;
      return fallback;
    }

    return Song(
      id: idStr.isNotEmpty ? idStr : 'song_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Untitled Lullaby',
      artist: json['artist'] as String? ?? (isCustom ? 'My Custom Lullaby (Parent)' : 'Maatriva Sound Studio'),
      duration: Duration(seconds: json['durationSeconds'] as int? ?? (json['duration'] as int? ?? 210)),
      category: rawCategory,
      genre: genreStr,
      isFavorite: json['isFavorite'] as bool? ?? false,
      albumArtColor: json['albumArtColor'] as String? ?? json['thumbnail'] as String? ?? 'violet',
      audioPath: audioPathVal,
      sourceType: resolvedSourceType,
      isCustomParentSong: isCustom,
      isSharedWithCaregiver: visibilityStr == 'SHARED_WITH_CAREGIVERS',
      visibility: visibilityStr,
      ownerId: uploadedBy,
      babyId: json['babyId'] as String?,
      aiBadge: json['aiBadge'] as String?,
      fileSize: json['fileSize'] as int? ?? 0,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      voiceFileUrl: json['voiceFileUrl'] as String? ?? audioPathVal,
      mixedFileUrl: json['mixedFileUrl'] as String? ?? audioPathVal,
      backgroundTrack: json['backgroundTrack'] as String?,
      bgAudioPath: json['bgAudioPath'] as String?,
      bgMusicVolume: (json['bgMusicVolume'] as num?)?.toDouble() ?? (json['musicVolume'] as num?)?.toDouble() ?? 0.4,
      voiceVolume: (json['voiceVolume'] as num?)?.toDouble() ?? 0.8,
      trimStartSeconds: (json['trimStartSeconds'] as num?)?.toDouble() ?? 0.0,
      trimEndSeconds: (json['trimEndSeconds'] as num?)?.toDouble(),
      introChime: json['introChime'] as String?,
      voicePreset: json['voicePreset'] as String?,
      fadeIn: parseDouble(json['fadeIn'], 1.0),
      fadeOut: parseDouble(json['fadeOut'], 1.0),
      noiseReduction: json['noiseReduction'] as bool? ?? true,
    );
  }
}
