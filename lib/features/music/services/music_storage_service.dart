import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_storage_stub.dart'
    if (dart.library.html) 'music_storage_web.dart';

class MusicStorageService {
  static const String _storageKey = 'maatriva_admin_uploaded_songs_v2';

  static Future<bool> saveSongs(String encodedJson) async {
    bool savedIndexedDb = false;
    bool savedPrefs = false;

    if (kIsWeb) {
      try {
        await saveToIndexedDB(_storageKey, encodedJson);
        savedIndexedDb = true;
      } catch (e) {
        debugPrint('[MusicStorageService] IndexedDB save error: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      savedPrefs = await prefs.setString(_storageKey, encodedJson);
    } catch (e) {
      debugPrint('[MusicStorageService] SharedPreferences save error: $e');
    }

    return savedIndexedDb || savedPrefs;
  }

  static Future<String?> loadSongs() async {
    if (kIsWeb) {
      try {
        final idbData = await loadFromIndexedDB(_storageKey);
        if (idbData != null && idbData.isNotEmpty) {
          return idbData;
        }
      } catch (e) {
        debugPrint('[MusicStorageService] IndexedDB load error: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_storageKey);
    } catch (e) {
      debugPrint('[MusicStorageService] SharedPreferences load error: $e');
      return null;
    }
  }
}
