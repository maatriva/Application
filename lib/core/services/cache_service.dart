import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline cache service for saving last known device status and sensor values.
class CacheService {
  final SharedPreferences _prefs;

  const CacheService(this._prefs);

  static const String _vitalsCacheKeyPrefix = 'maatriva_cache_vitals_';
  static const String _devicesCacheKey = 'maatriva_cache_devices';

  /// Save latest telemetry payload map for a device.
  Future<void> cacheVitals(String deviceId, Map<String, dynamic> vitalsMap) async {
    final key = '$_vitalsCacheKeyPrefix$deviceId';
    await _prefs.setString(key, jsonEncode(vitalsMap));
  }

  /// Retrieve last known cached vitals map for a device.
  Map<String, dynamic>? getCachedVitals(String deviceId) {
    final key = '$_vitalsCacheKeyPrefix$deviceId';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cache list of paired device registry items.
  Future<void> cacheDevices(List<Map<String, dynamic>> devicesList) async {
    await _prefs.setString(_devicesCacheKey, jsonEncode(devicesList));
  }

  /// Get cached list of devices.
  List<Map<String, dynamic>> getCachedDevices() {
    final jsonStr = _prefs.getString(_devicesCacheKey);
    if (jsonStr == null) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clears cache.
  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_vitalsCacheKeyPrefix) || key == _devicesCacheKey) {
        await _prefs.remove(key);
      }
    }
  }
}
