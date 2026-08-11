import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/models/user_session.dart';
import '../data/mock_songs.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/music_storage_service.dart';
import '../services/audio_scanner_service.dart';

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

  // Filter / sort / AI Auto mode
  final String? activeCategory;   // sub-category filter ('Lullabies', 'White Noise', …)
  final String? activeGenre;      // broad genre filter ('Classic Lullabies', …)
  final String? activePlaylist;
  final String searchQuery;
  final SortMode sortMode;
  final bool isLoadingCustom;

  // Smart Baby Sleep Care fields
  final bool isAutoSleepModeEnabled;
  final String activeFilterTab; // 'AI Recommendation', 'Recently Played', 'Favorites', 'Parent Recordings'

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
    this.isLoadingCustom = false,
    this.isAutoSleepModeEnabled = false,
    this.activeFilterTab = 'AI Recommendation',
  });

  // ── Derived lists ─────────────────────────────────────────────────────────
  List<Song> get favoriteSongs => songs.where((s) => s.isFavorite).toList();

  /// Full filtered + sorted list used by the library/search view.
  List<Song> get filteredSongs {
    var list = songs;

    if (activeFilterTab == 'Parent Recordings') {
      list = list.where((s) => s.isCustomParentSong || s.category == 'Parent Voice' || s.category == 'Parent Recordings').toList();
    } else if (activeFilterTab == 'Favorites') {
      list = list.where((s) => s.isFavorite).toList();
    } else if (activeFilterTab == 'Recently Played') {
      list = list.where((s) => s.recentlyPlayedAt != null || recentlyPlayed.any((r) => r.id == s.id)).toList();
    } else if (activeFilterTab == 'AI Recommendation') {
      // Show AI recommended catalog items or custom items with aiBadge
      list = List<Song>.from(list);
    }

    if (activeGenre != null) {
      if (activeGenre == "Parent's Melody Vault" || activeGenre == 'Custom Parent Folder' || activeGenre == 'Custom Parent Lullabies') {
        list = list.where((s) => s.isCustomParentSong || s.genre == "Parent's Melody Vault" || s.genre == 'Custom Parent Folder').toList();
      } else {
        list = list.where((s) => s.genre == activeGenre).toList();
      }
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
              s.category.toLowerCase().contains(q) ||
              (s.aiBadge?.toLowerCase().contains(q) ?? false))
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
    bool? isLoadingCustom,
    bool? isAutoSleepModeEnabled,
    String? activeFilterTab,
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
      isLoadingCustom: isLoadingCustom ?? this.isLoadingCustom,
      isAutoSleepModeEnabled: isAutoSleepModeEnabled ?? this.isAutoSleepModeEnabled,
      activeFilterTab: activeFilterTab ?? this.activeFilterTab,
    );
  }
}

// ── Global static catalog for admin uploaded songs so they persist across sessions and roles ──
final List<Song> _globalAdminUploadedSongs = [];

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
            songs: [..._globalAdminUploadedSongs, ...rawMockSongs],
            recentlyPlayed: [],
          ),
        ) {
    _audio.setVolume(state.volume);
    _loadStoredAndBackendSongs();
  }

  Future<void> _loadStoredAndBackendSongs() async {
    state = state.copyWith(isLoadingCustom: true);
    _globalAdminUploadedSongs.clear();

    try {
      final savedJson = await MusicStorageService.loadSongs();
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        for (final item in decoded) {
          final s = Song.fromJson(item as Map<String, dynamic>);
          final existingIdx = _globalAdminUploadedSongs.indexWhere((existing) => existing.id == s.id);
          if (existingIdx != -1) {
            _globalAdminUploadedSongs[existingIdx] = s;
          } else {
            _globalAdminUploadedSongs.add(s);
          }
        }
      }
    } catch (e) {
      debugPrint('[MusicProvider] Storage load error: $e');
    }

    try {
      final secureStorage = const SecureStorageService();
      final token = await secureStorage.getAccessToken();
      final userRoleStr = await secureStorage.getUserRole() ?? 'PARENT';
      final userRole = parseRole(userRoleStr);

      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // 1. Fetch general public music catalog
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/music?limit=100'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> tracks = data['tracks'] ?? data['data'] ?? [];
        for (final t in tracks) {
          final s = Song.fromJson(t as Map<String, dynamic>);
          final existingIdx = _globalAdminUploadedSongs.indexWhere((existing) => existing.id == s.id);
          if (existingIdx != -1) {
            _globalAdminUploadedSongs[existingIdx] = s;
          } else {
            _globalAdminUploadedSongs.add(s);
          }
        }
      }

      // 2. Fetch Parent Custom Lullabies OR Caregiver Shared Lullabies
      if (userRole == UserRole.parent) {
        debugPrint('[Music] Parent Login');
        debugPrint('[Music] Loading custom lullabies...');
        debugPrint('[Music] GET /music/custom');

        final customRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/music/custom'),
          headers: headers,
        );
        if (customRes.statusCode == 200) {
          final customData = jsonDecode(customRes.body);
          final List<dynamic> customTracks = customData['data'] ?? [];
          debugPrint('[Music] Songs received: ${customTracks.length}');
          if (customTracks.isEmpty) {
            debugPrint('[Music] Empty response');
          } else {
            for (final t in customTracks) {
              var s = Song.fromJson(t as Map<String, dynamic>);
              final existingIdx = _globalAdminUploadedSongs.indexWhere((existing) => existing.id == s.id);
              if (existingIdx != -1) {
                _globalAdminUploadedSongs[existingIdx] = s;
              } else {
                _globalAdminUploadedSongs.add(s);
              }
            }
          }
        } else {
          debugPrint('[Music] Empty response');
        }
        debugPrint('[Music] Rendering songs');
      } else if (userRole == UserRole.caregiver) {
        final sharedRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/music/shared'),
          headers: headers,
        );
        if (sharedRes.statusCode == 200) {
          final sharedData = jsonDecode(sharedRes.body);
          final List<dynamic> sharedTracks = sharedData['data'] ?? [];
          for (final t in sharedTracks) {
            var s = Song.fromJson(t as Map<String, dynamic>);
            final existingIdx = _globalAdminUploadedSongs.indexWhere((existing) => existing.id == s.id);
            if (existingIdx != -1) {
              _globalAdminUploadedSongs[existingIdx] = s;
            } else {
              _globalAdminUploadedSongs.add(s);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[MusicProvider] Backend catalog load error: $e');
    }

    try {
      final scannedAssetSongs = await AudioScannerService.scanAudioAsSongs();
      for (final s in scannedAssetSongs) {
        final existingIdx = _globalAdminUploadedSongs.indexWhere((existing) => existing.id == s.id);
        if (existingIdx != -1) {
          _globalAdminUploadedSongs[existingIdx] = s;
        } else {
          _globalAdminUploadedSongs.add(s);
        }
      }
    } catch (e) {
      debugPrint('[MusicProvider] Asset scan error: $e');
    }

    final all = [..._globalAdminUploadedSongs, ...rawMockSongs];
    state = state.copyWith(
      songs: all,
      currentSong: state.currentSong ?? (all.isNotEmpty ? all.first : null),
      isLoadingCustom: false,
    );
  }

  /// Reloads the persisted catalogue without resetting the selected song or
  /// filters. Call this after an upload, login, and from a pull-to-refresh action.
  Future<void> refreshLibrary() => _loadStoredAndBackendSongs();

  /// Clears in-memory custom songs on user logout
  void clearSessionMusicData() {
    _globalAdminUploadedSongs.clear();
    state = MusicState(
      songs: [...rawMockSongs],
      recentlyPlayed: [],
      isLoadingCustom: false,
    );
  }

  // ── Add Custom Song ───────────────────────────────────────────────────────
  Future<bool> addCustomSong(Song song) async {
    final secureStorage = const SecureStorageService();
    final userRole = await secureStorage.getUserRole();
    if (userRole?.toUpperCase() == 'CAREGIVER') {
      debugPrint('[MusicProvider] Caregivers are not permitted to add custom song.');
      return false;
    }

    return await _syncCustomSongToBackend(song);
  }

  Future<bool> _syncCustomSongToBackend(Song song) async {
    // Add to local state list immediately for responsive UI
    if (!_globalAdminUploadedSongs.any((s) => s.id == song.id)) {
      _globalAdminUploadedSongs.insert(0, song);
      await _persistSongsLocally();
      final updatedSongs = [..._globalAdminUploadedSongs, ...rawMockSongs];
      state = state.copyWith(songs: updatedSongs);
    }

    try {
      final secureStorage = const SecureStorageService();
      final token = await secureStorage.getAccessToken();

      debugPrint('[Music] POST /music/custom');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/music/custom');

      http.Response response;

      if (song.audioPath.startsWith('/') || song.audioPath.startsWith('C:') || song.audioPath.startsWith('D:')) {
        // Multipart upload for local disk file
        final request = http.MultipartRequest('POST', uri);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.fields['title'] = song.title;
        request.fields['category'] = song.category.isNotEmpty ? song.category : 'CUSTOM_PARENT';
        request.fields['duration'] = song.duration.inSeconds.toString();
        request.fields['shareWithCaregiver'] = song.isSharedWithCaregiver.toString();
        request.fields['visibility'] = song.isSharedWithCaregiver ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE';
        if (song.ownerId != null) request.fields['ownerId'] = song.ownerId!;
        if (song.babyId != null) request.fields['babyId'] = song.babyId!;
        if (song.backgroundTrack != null) request.fields['backgroundTrack'] = song.backgroundTrack!;
        if (song.bgAudioPath != null) request.fields['bgAudioPath'] = song.bgAudioPath!;
        request.fields['voiceVolume'] = song.voiceVolume.toString();
        request.fields['musicVolume'] = song.bgMusicVolume.toString();
        request.fields['bgMusicVolume'] = song.bgMusicVolume.toString();
        request.fields['fadeIn'] = song.fadeIn.toString();
        request.fields['fadeOut'] = song.fadeOut.toString();
        request.fields['noiseReduction'] = song.noiseReduction.toString();

        request.files.add(await http.MultipartFile.fromPath('audioFile', song.audioPath));
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        // Base64 or direct URL payload
        final headers = <String, String>{
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };

        final body = jsonEncode({
          'title': song.title,
          'category': song.category.isNotEmpty ? song.category : 'CUSTOM_PARENT',
          'duration': song.duration.inSeconds,
          'fileUrl': song.audioPath,
          'storageUrl': song.audioPath,
          'audioPath': song.audioPath,
          'voiceFileUrl': song.voiceFileUrl ?? song.audioPath,
          'mixedFileUrl': song.mixedFileUrl ?? song.audioPath,
          'backgroundTrack': song.backgroundTrack,
          'bgAudioPath': song.bgAudioPath,
          'voiceVolume': song.voiceVolume,
          'musicVolume': song.bgMusicVolume,
          'bgMusicVolume': song.bgMusicVolume,
          'fadeIn': song.fadeIn,
          'fadeOut': song.fadeOut,
          'noiseReduction': song.noiseReduction,
          'trimStartSeconds': song.trimStartSeconds,
          'trimEndSeconds': song.trimEndSeconds,
          'ownerId': song.ownerId,
          'babyId': song.babyId,
          'createdAt': (song.createdAt ?? DateTime.now()).toIso8601String(),
          'shareWithCaregiver': song.isSharedWithCaregiver,
          'visibility': song.isSharedWithCaregiver ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE',
          'base64Data': song.audioPath.contains('base64,')
              ? song.audioPath.split('base64,').last
              : null,
        });

        response = await http.post(uri, headers: headers, body: body);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[Music] Upload Success');
      } else {
        debugPrint('[MusicProvider] Sync custom song response status (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[MusicProvider] Sync custom song to backend error: $e');
    }
    return true;
  }

  // ── Delete Custom Song ────────────────────────────────────────────────────
  Future<bool> deleteCustomSong(String songId) async {
    try {
      final secureStorage = const SecureStorageService();
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final res = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/music/$songId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        debugPrint('[MusicProvider] DELETE /api/music/$songId response: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[MusicProvider] Delete custom song backend call error: $e');
    }

    _globalAdminUploadedSongs.removeWhere((s) => s.id == songId);
    final updatedSongs = state.songs.where((s) => s.id != songId).toList();

    Song? updatedCurrent = state.currentSong;
    if (updatedCurrent?.id == songId) {
      updatedCurrent = updatedSongs.isNotEmpty ? updatedSongs.first : null;
    }

    state = state.copyWith(
      songs: updatedSongs,
      currentSong: updatedCurrent,
    );
    await _persistSongsLocally();
    return true;
  }

  /// Clears all songs from the Parent Folder / Custom storage
  Future<bool> clearAllParentSongs() async {
    _globalAdminUploadedSongs.clear();
    state = state.copyWith(
      songs: [],
      clearCurrentSong: true,
      isLoadingCustom: false,
    );
    await MusicStorageService.saveSongs('[]');
    return true;
  }

  // ── Toggle Auto Sleep Mode ───────────────────────────────────────────────
  void toggleAutoSleepMode([bool? enabled]) {
    final next = enabled ?? !state.isAutoSleepModeEnabled;
    state = state.copyWith(isAutoSleepModeEnabled: next);
  }

  // ── Set Active Filter Tab ────────────────────────────────────────────────
  void setActiveFilterTab(String tab) {
    state = state.copyWith(activeFilterTab: tab);
  }

  // ── Toggle Caregiver Sharing Permission for Parent Songs ──────────────────
  void toggleCaregiverSharing(String songId) {
    final s = state.songs.firstWhere((item) => item.id == songId, orElse: () => state.songs.first);
    toggleSongShareStatus(songId, !s.isSharedWithCaregiver);
  }

  Future<bool> _persistSongsLocally() async {
    try {
      final encoded = jsonEncode(_globalAdminUploadedSongs.map((s) => s.toJson()).toList());
      return await MusicStorageService.saveSongs(encoded);
    } catch (e) {
      debugPrint('[MusicProvider] Storage save error: $e');
      return false;
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
      isPlaying: false,
      recentlyPlayed: recent,
    );

    // Play audio using exact song source
    bool success = false;
    try {
      await _audio.setVolume(state.volume);
      if (song.audioPath.isNotEmpty) {
        success = await _audio.playSong(song);
      }
    } catch (e) {
      debugPrint('Playback Error: $e');
    }

    if (success) {
      state = state.copyWith(isPlaying: true);
      _startPlaybackTimer();
    } else {
      debugPrint('Unable to play this audio.');
      _stopPlaybackTimer();
      state = state.copyWith(isPlaying: false);
    }
  }

  // ── Play / Pause ──────────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (state.currentSong == null) return;
    final nextPlaying = !state.isPlaying;
    if (nextPlaying) {
      bool resumed = await _audio.resume();
      if (!resumed && state.currentSong != null && state.currentSong!.audioPath.isNotEmpty) {
        resumed = await _audio.playSong(state.currentSong!);
      }
      if (resumed) {
        state = state.copyWith(isPlaying: true);
        _startPlaybackTimer();
      } else {
        debugPrint('Unable to play this audio.');
        _stopPlaybackTimer();
        state = state.copyWith(isPlaying: false);
      }
    } else {
      await _audio.pause();
      _stopPlaybackTimer();
      state = state.copyWith(isPlaying: false);
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
    await _audio.seek(clamped);
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

  /// Toggle caregiver sharing status for a single custom song
  Future<bool> toggleSongShareStatus(String songId, bool shareWithCaregivers) async {
    try {
      final secureStorage = const SecureStorageService();
      final token = await secureStorage.getAccessToken();
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/music/custom/$songId/share'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shareWithCaregivers': shareWithCaregivers}),
      );

      final newVisibility = shareWithCaregivers ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE';

      // Update local state and global catalog
      final updatedSongs = state.songs.map((s) {
        if (s.id == songId) {
          return s.copyWith(
            visibility: newVisibility,
            isSharedWithCaregiver: shareWithCaregivers,
          );
        }
        return s;
      }).toList();

      for (int i = 0; i < _globalAdminUploadedSongs.length; i++) {
        if (_globalAdminUploadedSongs[i].id == songId) {
          _globalAdminUploadedSongs[i] = _globalAdminUploadedSongs[i].copyWith(
            visibility: newVisibility,
            isSharedWithCaregiver: shareWithCaregivers,
          );
        }
      }

      await _persistSongsLocally();
      state = state.copyWith(songs: updatedSongs);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[MusicProvider] Toggle song share error: $e');
      return false;
    }
  }

  /// Toggle caregiver sharing status for ALL custom parent songs (Share Entire Custom Folder)
  Future<bool> toggleAllCustomSongsShareStatus(bool shareWithCaregivers) async {
    try {
      final secureStorage = const SecureStorageService();
      final token = await secureStorage.getAccessToken();
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/music/custom/share-all'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shareWithCaregivers': shareWithCaregivers}),
      );

      final newVisibility = shareWithCaregivers ? 'SHARED_WITH_CAREGIVERS' : 'PRIVATE';

      final updatedSongs = state.songs.map((s) {
        if (s.isCustomParentSong) {
          return s.copyWith(
            visibility: newVisibility,
            isSharedWithCaregiver: shareWithCaregivers,
          );
        }
        return s;
      }).toList();

      for (int i = 0; i < _globalAdminUploadedSongs.length; i++) {
        if (_globalAdminUploadedSongs[i].isCustomParentSong) {
          _globalAdminUploadedSongs[i] = _globalAdminUploadedSongs[i].copyWith(
            visibility: newVisibility,
            isSharedWithCaregiver: shareWithCaregivers,
          );
        }
      }

      await _persistSongsLocally();
      state = state.copyWith(songs: updatedSongs);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[MusicProvider] Toggle all custom songs share error: $e');
      return false;
    }
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
