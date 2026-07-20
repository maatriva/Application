class Song {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String category;
  final bool isFavorite;
  final String
  albumArtColor; // We'll use beautiful color gradients for cards in the UI

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.category,
    this.isFavorite = false,
    required this.albumArtColor,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    String? category,
    bool? isFavorite,
    String? albumArtColor,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      albumArtColor: albumArtColor ?? this.albumArtColor,
    );
  }
}
