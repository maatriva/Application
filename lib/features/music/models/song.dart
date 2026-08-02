class Song {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String category;    // specific sub-category (Lullabies, Rain Sounds, etc.)
  final String genre;       // broad genre label (Classic Lullabies, White Noise, etc.)
  final bool isFavorite;
  final String albumArtColor;
  final String audioPath;         // asset path relative to assets/ (e.g. 'audio/lullaby_classic.wav')
  final DateTime? recentlyPlayedAt; // updated each time the song is played
  final bool isCustomParentSong;   // true if imported/custom parent music

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
    this.recentlyPlayedAt,
    this.isCustomParentSong = false,
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
    DateTime? recentlyPlayedAt,
    bool clearRecentlyPlayedAt = false,
    bool? isCustomParentSong,
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
      recentlyPlayedAt: clearRecentlyPlayedAt
          ? null
          : (recentlyPlayedAt ?? this.recentlyPlayedAt),
      isCustomParentSong: isCustomParentSong ?? this.isCustomParentSong,
    );
  }
}
