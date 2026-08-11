import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/song.dart';

/// Helper service that dynamically scans uploaded songs from the backend API
/// (`/api/music`) as well as local `assets/audio/` at runtime.
class AudioScannerService {
  /// Scans backend uploaded tracks (`backend/uploads/music/`) & `assets/audio/` to return structured track info for background music pickers.
  static Future<List<Map<String, dynamic>>> scanBgMusicTracks() async {
    final List<Map<String, dynamic>> tracks = [];
    final Set<String> addedNames = {};

    // 1. Fetch dedicated BGM tracks from backend/uploads/bgm/ folder
    try {
      final bgmUrl = Uri.parse('${ApiConfig.baseUrl}/api/music/bgm');
      final response = await http.get(bgmUrl).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bgmTracks = data['data'] ?? data['tracks'] ?? [];
        for (int i = 0; i < bgmTracks.length; i++) {
          final t = bgmTracks[i];
          final rawTitle = (t['title'] as String? ?? '').trim();
          final storageUrl = (t['storageUrl'] as String? ?? t['fileUrl'] as String? ?? t['audioPath'] as String? ?? '').trim();

          if (storageUrl.isNotEmpty) {
            final cleanName = rawTitle.isNotEmpty ? _formatName(rawTitle) : 'BGM ${i + 1}';
            if (!addedNames.contains(cleanName.toLowerCase())) {
              addedNames.add(cleanName.toLowerCase());
              tracks.add({
                'id': t['id'] ?? t['songId'],
                'name': cleanName,
                'icon': _getIconForName(cleanName),
                'desc': 'Recording BGM Folder',
                'color': _getColorForIndex(tracks.length),
                'audioUrl': storageUrl,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioScannerService] Could not fetch dedicated /api/music/bgm: $e');
    }

    // 2. Fallback to general catalog if /uploads/bgm/ is empty
    if (tracks.isEmpty) {
      try {
        final backendUrl = Uri.parse('${ApiConfig.baseUrl}/api/music?limit=100');
        final response = await http.get(backendUrl).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> backendTracks = data['data'] ?? data['tracks'] ?? [];
          
          for (int i = 0; i < backendTracks.length; i++) {
            final t = backendTracks[i];
            final rawTitle = (t['title'] as String? ?? '').trim();
            final storageUrl = (t['storageUrl'] as String? ?? t['fileUrl'] as String? ?? t['audioPath'] as String? ?? '').trim();

            if (storageUrl.isNotEmpty) {
              final category = (t['category'] as String? ?? 'Folder Audio');
              final cleanName = rawTitle.isNotEmpty ? _formatName(rawTitle) : 'Track ${i + 1}';

              if (_isSuitableForBackground(cleanName, category, storageUrl)) {
                if (!addedNames.contains(cleanName.toLowerCase())) {
                  addedNames.add(cleanName.toLowerCase());
                  tracks.add({
                    'id': t['id'] ?? t['songId'],
                    'name': cleanName,
                    'icon': _getIconForName(cleanName),
                    'desc': category,
                    'color': _getColorForIndex(tracks.length),
                    'audioUrl': storageUrl,
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AudioScannerService] Could not fetch backend music catalog fallback: $e');
      }
    }

    // 2. Scan local asset folder if present
    try {
      final String manifestContent =
          await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final List<String> audioAssets = manifestMap.keys.where((String key) {
        if (!key.startsWith('assets/audio/')) return false;
        final lower = key.toLowerCase();
        return lower.endsWith('.wav') ||
            lower.endsWith('.mp3') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.ogg') ||
            lower.endsWith('.aac') ||
            lower.endsWith('.flac');
      }).toList();

      audioAssets.sort();

      for (int i = 0; i < audioAssets.length; i++) {
        final path = audioAssets[i];
        final filename = path.split('/').last;
        final rawName = filename.replaceAll(RegExp(r'\.[^/.]+$'), '');
        final cleanName = _formatName(rawName);

        if (_isSuitableForBackground(cleanName, 'Asset', path)) {
          if (!addedNames.contains(cleanName.toLowerCase())) {
            addedNames.add(cleanName.toLowerCase());
            tracks.add({
              'name': cleanName,
              'icon': _getIconForName(cleanName),
              'desc': _getDescForName(cleanName),
              'color': _getColorForIndex(tracks.length),
              'audioUrl': path,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioScannerService] Error scanning assets: $e');
    }

    return tracks;
  }

  /// Scans `assets/audio/` and returns a list of playable [Song] models.
  static Future<List<Song>> scanAudioAsSongs() async {
    final List<Song> songs = [];

    try {
      final String manifestContent =
          await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final List<String> audioAssets = manifestMap.keys.where((String key) {
        if (!key.startsWith('assets/audio/')) return false;
        final lower = key.toLowerCase();
        return lower.endsWith('.wav') ||
            lower.endsWith('.mp3') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.ogg') ||
            lower.endsWith('.aac') ||
            lower.endsWith('.flac');
      }).toList();

      audioAssets.sort();

      for (int i = 0; i < audioAssets.length; i++) {
        final path = audioAssets[i];
        final filename = path.split('/').last;
        final rawName = filename.replaceAll(RegExp(r'\.[^/.]+$'), '');
        final cleanName = _formatName(rawName);
        final category = _getCategoryForName(cleanName);

        final colorHex = _getColorHexForIndex(i);

        songs.add(
          Song(
            id: 'asset_audio_${i}_${rawName.toLowerCase()}',
            title: cleanName,
            artist: 'Maatriva Audio Library',
            duration: const Duration(minutes: 3, seconds: 30),
            category: category,
            genre: 'Asset Library',
            albumArtColor: colorHex,
            audioPath: path,
            sourceType: 'ASSET',
            aiBadge: _getAiBadgeForName(cleanName),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AudioScannerService] Error scanning assets into Songs: $e');
    }

    return songs;
  }

  static String _formatName(String raw) {
    var cleaned = raw.replaceAll(
      RegExp(r'^(apalonbeats|freemusicforvideo|pixabay|mixkit|audiojungle|elements)[_\-]', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[\-_]\d+$'), '');
    cleaned = cleaned
        .replaceAll(RegExp(r'[_\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'Background Track';

    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static IconData _getIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('piano') || lower.contains('key')) {
      return Icons.piano_rounded;
    }
    if (lower.contains('rain') || lower.contains('water') || lower.contains('drizzle')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('ocean') || lower.contains('wave') || lower.contains('sea')) {
      return Icons.sailing_rounded;
    }
    if (lower.contains('heart') || lower.contains('pulse')) {
      return Icons.favorite_rounded;
    }
    if (lower.contains('nature') || lower.contains('forest') || lower.contains('bird') || lower.contains('tree')) {
      return Icons.forest_rounded;
    }
    if (lower.contains('noise') || lower.contains('womb')) {
      return Icons.waves_rounded;
    }
    if (lower.contains('wind') || lower.contains('breeze') || lower.contains('air')) {
      return Icons.air_rounded;
    }
    if (lower.contains('humming') || lower.contains('vocal') || lower.contains('sing')) {
      return Icons.graphic_eq_rounded;
    }
    if (lower.contains('night') || lower.contains('sleep') || lower.contains('star')) {
      return Icons.nightlight_round;
    }
    return Icons.music_note_rounded;
  }

  static String _getDescForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('piano')) return 'Gentle acoustic piano notes';
    if (lower.contains('rain')) return 'Calming soft rain sounds';
    if (lower.contains('ocean')) return 'Rhythmic rolling waves';
    if (lower.contains('heart')) return 'Comforting maternal heartbeat pulse';
    if (lower.contains('nature') || lower.contains('forest')) return 'Peaceful natural environment';
    if (lower.contains('noise')) return 'Steady, soothing womb-like sound';
    if (lower.contains('wind')) return 'Whisper of gentle night breeze';
    if (lower.contains('night')) return 'Peaceful nocturnal sleep ambience';
    return 'Soothing background audio track';
  }

  static Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFE8EAFF),
      const Color(0xFFFFF0F5),
      const Color(0xFFE3F2FD),
      const Color(0xFFE0F7FA),
      const Color(0xFFE0F2F1),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFEBEE),
      const Color(0xFFF3E5F5),
      const Color(0xFFFFF8E1),
      const Color(0xFFECEFF1),
    ];
    return colors[index % colors.length];
  }

  static String _getColorHexForIndex(int index) {
    final colorHexes = [
      '#6C5CE7',
      '#FD79A8',
      '#0984E3',
      '#00CEC9',
      '#00B894',
      '#55E6C1',
      '#FF7675',
      '#A29BFE',
      '#FFEAA7',
      '#636E72',
    ];
    return colorHexes[index % colorHexes.length];
  }

  static String _getCategoryForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rain') || lower.contains('ocean') || lower.contains('nature') || lower.contains('wind')) {
      return 'Nature Sounds';
    }
    if (lower.contains('noise') || lower.contains('womb')) {
      return 'White Noise';
    }
    if (lower.contains('heart')) {
      return 'Womb Sounds';
    }
    return 'Lullabies';
  }

  static bool _isSuitableForBackground(String title, String category, String storageUrl) {
    final lowerTitle = title.toLowerCase();
    final lowerCat = category.toLowerCase();
    final lowerUrl = storageUrl.toLowerCase();

    // Explicitly exclude active vocal nursery rhymes
    if (lowerCat == 'nursery rhymes' || lowerCat == 'nursery_rhymes') {
      return false;
    }

    final rhymeKeywords = [
      'bus', 'wheels', 'finger', 'family', 'monkey', 'blacksheep', 'bingo',
      'alphabet', 'clap', 'hickory', 'birthday', 'teapot', 'muffin',
      'patacake', 'mountain', 'teddy', 'yankee', 'brotherjohn', 'rhyme'
    ];

    for (final kw in rhymeKeywords) {
      if (lowerTitle.contains(kw) || lowerUrl.contains(kw)) {
        return false;
      }
    }

    return true;
  }

  static String? _getAiBadgeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rain') || lower.contains('ocean')) return 'Recommended for Deep Sleep';
    if (lower.contains('noise') || lower.contains('womb')) return 'Best for Crying Baby';
    if (lower.contains('heart')) return 'Maternal Comfort';
    if (lower.contains('lullaby') || lower.contains('piano')) return 'Bedtime Calming';
    return null;
  }
}
