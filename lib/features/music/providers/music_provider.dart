import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_songs.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

// ── Sort mode enum ──────────────────────────────────────────────────────────
enum SortMode { alphabetical, recentlyPlayed, favorites, duration }

// ── State ───────────────────────────────────────────────────────────────────
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

  // Filter / sort
  final String? activeCategory;   // sub-category filter ('Lullabies', 'White Noise', …)
  final String? activeGenre;      // broad genre filter ('Classic Lullabies', …)
  final String? activePlaylist;
  final String searchQuery;
  final SortMode sortMode;

  const MusicState({
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
    this.activeGenre,
    this.activePlaylist,
    this.searchQuery = '',
    this.sortMode = SortMode.alphabetical,
  });

  // ── Derived lists ─────────────────────────────────────────────────────────
  List<Song> get favoriteSongs => songs.where((s) => s.isFavorite).toList();

  /// Full filtered + sorted list used by the library/search view.
  List<Song> get filteredSongs {
    var list = songs;

    if (activeGenre != null) {
      list = list.where((s) => s.genre == activeGenre).toList();
    } else if (activeCategory != null) {
      list = list.where((s) => s.category == activeCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.genre.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q))
          .toList();
    }

    return _applySort(list);
  }

  List<Song> _applySort(List<Song> list) {
    final copy = List<Song>.from(list);
    switch (sortMode) {
      case SortMode.alphabetical:
        copy.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.recentlyPlayed:
        copy.sort((a, b) {
          final aTime = a.recentlyPlayedAt;
          final bTime = b.recentlyPlayedAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        break;
      case SortMode.favorites:
        copy.sort((a, b) {
          if (a.isFavorite == b.isFavorite) return a.title.compareTo(b.title);
          return a.isFavorite ? -1 : 1;
        });
        break;
      case SortMode.duration:
        copy.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    return copy;
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
    String? activeGenre,
    String? activePlaylist,
    String? searchQuery,
    SortMode? sortMode,
    bool clearCurrentSong = false,
    bool clearSleepTimer = false,
    bool clearCategoryFilter = false,
    bool clearGenreFilter = false,
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
      sleepTimerTotal:
          clearSleepTimer ? null : (sleepTimerTotal ?? this.sleepTimerTotal),
      activeCategory: clearCategoryFilter
          ? null
          : (activeCategory == 'All'
              ? null
              : (activeCategory ?? this.activeCategory)),
      activeGenre: clearGenreFilter
          ? null
          : (activeGenre == 'All' ? null : (activeGenre ?? this.activeGenre)),
      activePlaylist: activePlaylist ?? this.activePlaylist,
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class MusicNotifier extends StateNotifier<MusicState> {
  final AudioService _audio = AudioService();

  // Progress timer — drives the UI seek bar (the WAV loops, so we track
  // "virtual" progress separately against the song's stated duration).
  Timer? _playbackTimer;
  Timer? _sleepTimer;

  MusicNotifier()
      : super(
          MusicState(
            songs: List<Song>.from(rawMockSongs),
            recentlyPlayed: [],
          ),
        ) {
    _audio.setVolume(state.volume);
    if (state.songs.isNotEmpty) {
      state = state.copyWith(currentSong: state.songs.first);
    }
  }

  // ── Song selection ────────────────────────────────────────────────────────
  Future<void> selectSong(Song song) async {
    _stopPlaybackTimer();

    // Stamp recentlyPlayedAt on the song
    final now = DateTime.now();
    final updatedSongs = state.songs.map((s) {
      if (s.id == song.id) return s.copyWith(recentlyPlayedAt: now);
      return s;
    }).toList();

    final updatedSong = song.copyWith(recentlyPlayedAt: now);

    // Build recently played list
    final recent = List<Song>.from(state.recentlyPlayed);
    recent.removeWhere((s) => s.id == song.id);
    recent.insert(0, updatedSong);
    if (recent.length > 10) recent.removeLast();

    state = state.copyWith(
      songs: updatedSongs,
      currentSong: updatedSong,
      currentPosition: Duration.zero,
      isPlaying: true,
      recentlyPlayed: recent,
    );

    // Play audio
    try {
      await _audio.setVolume(state.volume);
      if (song.audioPath.isNotEmpty) {
        await _audio.playAsset(song.audioPath);
      }
    } catch (e) {
      debugPrint('[AudioService] playback error: $e');
    }

    _startPlaybackTimer();
  }

  // ── Play / Pause ──────────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (state.currentSong == null) return;
    final nextPlaying = !state.isPlaying;
    state = state.copyWith(isPlaying: nextPlaying);
    if (nextPlaying) {
      await _audio.resume();
      _startPlaybackTimer();
    } else {
      await _audio.pause();
      _stopPlaybackTimer();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> nextTrack() async {
    final list = _getFilteredSongs();
    if (list.isEmpty) return;
    final Song next;
    if (state.isShuffle) {
      next = list[Random().nextInt(list.length)];
    } else {
      final idx = list.indexWhere((s) => s.id == state.currentSong?.id);
      next = (idx == -1 || idx == list.length - 1) ? list.first : list[idx + 1];
    }
    await selectSong(next);
  }

  Future<void> previousTrack() async {
    final list = _getFilteredSongs();
    if (list.isEmpty) return;
    final Song prev;
    if (state.isShuffle) {
      prev = list[Random().nextInt(list.length)];
    } else {
      final idx = list.indexWhere((s) => s.id == state.currentSong?.id);
      prev = (idx == -1 || idx == 0) ? list.last : list[idx - 1];
    }
    await selectSong(prev);
  }

  // ── Seek ──────────────────────────────────────────────────────────────────
  Future<void> seek(Duration position) async {
    if (state.currentSong == null) return;
    final max = state.currentSong!.duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > max ? max : position);
    state = state.copyWith(currentPosition: clamped);
    // Note: audio loops the short WAV; seeking in the simulated progress only.
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  void toggleShuffle() => state = state.copyWith(isShuffle: !state.isShuffle);
  void toggleRepeat() => state = state.copyWith(isRepeat: !state.isRepeat);

  Future<void> setVolume(double vol) async {
    state = state.copyWith(volume: vol.clamp(0.0, 1.0));
    await _audio.setVolume(state.volume);
  }

  void setPlaybackSpeed(double speed) =>
      state = state.copyWith(playbackSpeed: speed);

  // ── Filters / Sort ────────────────────────────────────────────────────────
  void setCategoryFilter(String? category) {
    state = state.copyWith(
      activeCategory: category,
      clearGenreFilter: true,
    );
  }

  void setGenreFilter(String? genre) {
    state = state.copyWith(
      activeGenre: genre,
      clearCategoryFilter: true,
    );
  }

  void clearAllFilters() {
    state = state.copyWith(
      clearCategoryFilter: true,
      clearGenreFilter: true,
      searchQuery: '',
    );
  }

  void setPlaylistFilter(String? name) =>
      state = state.copyWith(activePlaylist: name);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void setSortMode(SortMode mode) => state = state.copyWith(sortMode: mode);

  // ── Favorites ─────────────────────────────────────────────────────────────
  void toggleFavorite(String songId) {
    final updated = state.songs.map((s) {
      if (s.id == songId) return s.copyWith(isFavorite: !s.isFavorite);
      return s;
    }).toList();

    Song? updatedCurrent = state.currentSong;
    if (updatedCurrent != null && updatedCurrent.id == songId) {
      updatedCurrent =
          updatedCurrent.copyWith(isFavorite: !updatedCurrent.isFavorite);
    }

    state = state.copyWith(songs: updated, currentSong: updatedCurrent);
  }

  // ── Sleep timer ───────────────────────────────────────────────────────────
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    state = state.copyWith(
      sleepTimerRemaining: duration,
      sleepTimerTotal: duration,
    );
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.sleepTimerRemaining == null) {
        t.cancel();
        return;
      }
      final next = state.sleepTimerRemaining! - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        t.cancel();
        _audio.pause();
        _stopPlaybackTimer();
        state = state.copyWith(isPlaying: false, clearSleepTimer: true);
      } else {
        state = state.copyWith(sleepTimerRemaining: next);
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    state = state.copyWith(clearSleepTimer: true);
  }

  // ── Playlist helper ───────────────────────────────────────────────────────
  List<Song> getSongsForPlaylist(String playlist, List<Song> all) {
    switch (playlist) {
      case 'Favorites':
        return all.where((s) => s.isFavorite).toList();
      case 'Newborn Sleep':
        return all
            .where((s) =>
                s.genre == 'Heartbeat & Womb' || s.genre == 'White Noise')
            .toList();
      case 'Night Sleep':
        return all
            .where((s) =>
                s.genre == 'Classic Lullabies' || s.genre == 'Instrumental')
            .toList();
      case 'Nap Time':
        return all
            .where((s) => s.genre == 'Nature Sounds')
            .toList();
      case 'White Noise Collection':
        return all.where((s) => s.genre == 'White Noise').toList();
      case 'Calming Sounds':
        return all.where((s) => s.genre == 'Sleep Meditation').toList();
      case 'Classical Collection':
        return all.where((s) => s.category == 'Classical').toList();
      case 'Nature Collection':
        return all.where((s) => s.genre == 'Nature Sounds').toList();
      default:
        return all;
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  List<Song> _getFilteredSongs() {
    var list = state.songs;
    if (state.activeGenre != null) {
      list = list.where((s) => s.genre == state.activeGenre).toList();
    } else if (state.activeCategory != null) {
      list = list.where((s) => s.category == state.activeCategory).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.genre.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || state.currentSong == null || !state.isPlaying) {
        t.cancel();
        return;
      }
      final added = Duration(seconds: state.playbackSpeed.round());
      final next = state.currentPosition + added;
      if (next >= state.currentSong!.duration) {
        if (state.isRepeat) {
          state = state.copyWith(currentPosition: Duration.zero);
        } else {
          nextTrack();
        }
      } else {
        state = state.copyWith(currentPosition: next);
      }
    });
  }

  void _stopPlaybackTimer() => _playbackTimer?.cancel();

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _sleepTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final musicProvider =
    StateNotifierProvider<MusicNotifier, MusicState>((ref) => MusicNotifier());
