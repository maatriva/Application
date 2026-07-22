import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../data/mock_songs.dart';

class MusicState {
  final List<Song> songs;
  final Song? currentSong;
  final bool isPlaying;
  final Duration currentPosition;
  final double playbackSpeed;
  final bool isShuffle;
  final bool isRepeat;
  final double volume;
  final List<Song> recentlyPlayed;
  final Duration? sleepTimerRemaining;
  final Duration? sleepTimerTotal;
  final String? activeCategory;
  final String? activePlaylist;
  final String searchQuery;

  MusicState({
    required this.songs,
    this.currentSong,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isShuffle = false,
    this.isRepeat = false,
    this.volume = 0.7,
    required this.recentlyPlayed,
    this.sleepTimerRemaining,
    this.sleepTimerTotal,
    this.activeCategory,
    this.activePlaylist,
    this.searchQuery = '',
  });

  List<Song> get filteredSongs {
    var filtered = songs;
    if (activeCategory != null) {
      filtered = filtered.where((s) => s.category == activeCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query),
          )
          .toList();
    }
    return filtered;
  }

  MusicState copyWith({
    List<Song>? songs,
    Song? currentSong,
    bool? isPlaying,
    Duration? currentPosition,
    double? playbackSpeed,
    bool? isShuffle,
    bool? isRepeat,
    double? volume,
    List<Song>? recentlyPlayed,
    Duration? sleepTimerRemaining,
    Duration? sleepTimerTotal,
    String? activeCategory,
    String? activePlaylist,
    String? searchQuery,
    bool clearCurrentSong = false,
    bool clearSleepTimer = false,
  }) {
    return MusicState(
      songs: songs ?? this.songs,
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      volume: volume ?? this.volume,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      sleepTimerRemaining: clearSleepTimer
          ? null
          : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      sleepTimerTotal: clearSleepTimer
          ? null
          : (sleepTimerTotal ?? this.sleepTimerTotal),
      activeCategory: activeCategory == 'All'
          ? null
          : (activeCategory ?? this.activeCategory),
      activePlaylist: activePlaylist ?? this.activePlaylist,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MusicNotifier extends StateNotifier<MusicState> {
  Timer? _playbackTimer;
  Timer? _sleepTimer;

  MusicNotifier()
    : super(MusicState(songs: List.from(rawMockSongs), recentlyPlayed: [])) {
    // Set first song as default current song if none selected
    if (state.songs.isNotEmpty) {
      state = state.copyWith(currentSong: state.songs.first);
    }
  }

  void selectSong(Song song) {
    // Add to recently played (avoid duplicates at the front)
    final recent = List<Song>.from(state.recentlyPlayed);
    recent.removeWhere((s) => s.id == song.id);
    recent.insert(0, song);
    if (recent.length > 8) {
      recent.removeLast();
    }

    state = state.copyWith(
      currentSong: song,
      currentPosition: Duration.zero,
      isPlaying: true,
      recentlyPlayed: recent,
    );

    _startPlaybackTimer();
  }

  void togglePlayPause() {
    if (state.currentSong == null) return;

    final nextPlaying = !state.isPlaying;
    state = state.copyWith(isPlaying: nextPlaying);

    if (nextPlaying) {
      _startPlaybackTimer();
    } else {
      _stopPlaybackTimer();
    }
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }

  void setVolume(double vol) {
    state = state.copyWith(volume: vol.clamp(0.0, 1.0));
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(activeCategory: category);
  }

  void setPlaylistFilter(String? playlistName) {
    state = state.copyWith(activePlaylist: playlistName);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFavorite(String songId) {
    final updatedSongs = state.songs.map((s) {
      if (s.id == songId) {
        return s.copyWith(isFavorite: !s.isFavorite);
      }
      return s;
    }).toList();

    Song? updatedCurrentSong = state.currentSong;
    if (updatedCurrentSong != null && updatedCurrentSong.id == songId) {
      updatedCurrentSong = updatedCurrentSong.copyWith(
        isFavorite: !updatedCurrentSong.isFavorite,
      );
    }

    state = state.copyWith(
      songs: updatedSongs,
      currentSong: updatedCurrentSong,
    );
  }

  void seek(Duration position) {
    if (state.currentSong == null) return;
    final maxDuration = state.currentSong!.duration;
    final targetPosition = position > maxDuration
        ? maxDuration
        : (position < Duration.zero ? Duration.zero : position);
    state = state.copyWith(currentPosition: targetPosition);
  }

  void nextTrack() {
    final availableSongs = _getFilteredSongs();
    if (availableSongs.isEmpty) return;

    if (state.isShuffle) {
      final random = Random();
      final randomIndex = random.nextInt(availableSongs.length);
      selectSong(availableSongs[randomIndex]);
    } else {
      final currentIndex = availableSongs.indexWhere(
        (s) => s.id == state.currentSong?.id,
      );
      if (currentIndex == -1 || currentIndex == availableSongs.length - 1) {
        // Go back to first
        selectSong(availableSongs.first);
      } else {
        selectSong(availableSongs[currentIndex + 1]);
      }
    }
  }

  void previousTrack() {
    final availableSongs = _getFilteredSongs();
    if (availableSongs.isEmpty) return;

    if (state.isShuffle) {
      final random = Random();
      final randomIndex = random.nextInt(availableSongs.length);
      selectSong(availableSongs[randomIndex]);
    } else {
      final currentIndex = availableSongs.indexWhere(
        (s) => s.id == state.currentSong?.id,
      );
      if (currentIndex == -1 || currentIndex == 0) {
        // Go to last
        selectSong(availableSongs.last);
      } else {
        selectSong(availableSongs[currentIndex - 1]);
      }
    }
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    state = state.copyWith(
      sleepTimerRemaining: duration,
      sleepTimerTotal: duration,
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.sleepTimerRemaining == null) {
        timer.cancel();
        return;
      }

      final nextRemaining =
          state.sleepTimerRemaining! - const Duration(seconds: 1);
      if (nextRemaining <= Duration.zero) {
        timer.cancel();
        state = state.copyWith(isPlaying: false, clearSleepTimer: true);
        _stopPlaybackTimer();
      } else {
        state = state.copyWith(sleepTimerRemaining: nextRemaining);
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    state = state.copyWith(clearSleepTimer: true);
  }

  List<Song> _getFilteredSongs() {
    var list = state.songs;

    // Apply Playlist filter
    if (state.activePlaylist != null) {
      list = getSongsForPlaylist(state.activePlaylist!, list);
    }

    // Apply Category filter
    if (state.activeCategory != null) {
      list = list.where((s) => s.category == state.activeCategory).toList();
    }

    // Apply Search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query),
          )
          .toList();
    }

    return list;
  }

  List<Song> getSongsForPlaylist(String playlist, List<Song> allSongs) {
    switch (playlist) {
      case 'Favorites':
        return allSongs.where((s) => s.isFavorite).toList();
      case 'Newborn Sleep':
        return allSongs
            .where(
              (s) =>
                  s.category == 'Heartbeat Sounds' ||
                  s.category == 'White Noise',
            )
            .toList();
      case 'Night Sleep':
        return allSongs
            .where((s) => s.category == 'Lullabies' || s.category == 'Piano')
            .toList();
      case 'Nap Time':
        return allSongs
            .where(
              (s) =>
                  s.category == 'Nature Sounds' || s.category == 'Ocean Waves',
            )
            .toList();
      case 'White Noise Collection':
        return allSongs.where((s) => s.category == 'White Noise').toList();
      case 'Calming Sounds':
        return allSongs
            .where(
              (s) => s.category == 'Meditation' || s.category == 'Instrumental',
            )
            .toList();
      case 'Classical Collection':
        return allSongs.where((s) => s.category == 'Classical').toList();
      case 'Nature Collection':
        return allSongs
            .where(
              (s) =>
                  s.category == 'Nature Sounds' || s.category == 'Rain Sounds',
            )
            .toList();
      default:
        return allSongs;
    }
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.currentSong == null || !state.isPlaying) {
        timer.cancel();
        return;
      }

      // Progress playback speed adjusted
      final addedSeconds = (1 * state.playbackSpeed).round();
      final nextPosition =
          state.currentPosition + Duration(seconds: addedSeconds);

      if (nextPosition >= state.currentSong!.duration) {
        if (state.isRepeat) {
          state = state.copyWith(currentPosition: Duration.zero);
        } else {
          nextTrack();
        }
      } else {
        state = state.copyWith(currentPosition: nextPosition);
      }
    });
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _sleepTimer?.cancel();
    super.dispose();
  }
}

final musicProvider = StateNotifierProvider<MusicNotifier, MusicState>((ref) {
  return MusicNotifier();
});
