import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline cache service for saving last known device status, sensor values, theme preferences, and baby metadata.
class CacheService {
  final SharedPreferences _prefs;

  const CacheService(this._prefs);

  SharedPreferences get sharedPreferences => _prefs;

  static const String _vitalsCacheKeyPrefix = 'maatriva_cache_vitals_';
  static const String _devicesCacheKey = 'maatriva_cache_devices';
  static const String _userProfileKey = 'maatriva_cache_user_profile';
  static const String _selectedBabyIdKey = 'maatriva_cache_selected_baby_id';
  static const String _themeModeKey = 'maatriva_cache_theme_mode';

  /// Save latest telemetry payload map for a device.
  Future<void> cacheVitals(
    String deviceId,
    Map<String, dynamic> vitalsMap,
  ) async {
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

  /// Cache User Profile JSON.
  Future<void> cacheUserProfile(Map<String, dynamic> userProfileMap) async {
    await _prefs.setString(_userProfileKey, jsonEncode(userProfileMap));
  }

  /// Retrieve cached User Profile map.
  Map<String, dynamic>? getCachedUserProfile() {
    final jsonStr = _prefs.getString(_userProfileKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cache selected baby ID.
  Future<void> cacheSelectedBabyId(String babyId) async {
    await _prefs.setString(_selectedBabyIdKey, babyId);
  }

  /// Retrieve cached selected baby ID.
  String? getCachedSelectedBabyId() {
    return _prefs.getString(_selectedBabyIdKey);
  }

  static const String _selectedBabyKey = 'maatriva_cache_selected_baby';
  static const String _telemetryHistoryCacheKeyPrefix = 'maatriva_cache_telemetry_history_';
  static const String _alertsCacheKey = 'maatriva_cache_alerts';

  /// Cache theme mode preference.
  Future<void> cacheThemeMode(String themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode);
  }

  /// Retrieve cached theme mode preference.
  String? getCachedThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  /// Cache list of alerts.
  Future<void> cacheAlerts(List<Map<String, dynamic>> alertsJsonList) async {
    await _prefs.setString(_alertsCacheKey, jsonEncode(alertsJsonList));
  }

  /// Retrieve cached list of alerts.
  List<Map<String, dynamic>> getCachedAlerts() {
    final jsonStr = _prefs.getString(_alertsCacheKey);
    if (jsonStr == null) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Cache selected baby metadata.
  Future<void> cacheSelectedBaby(Map<String, dynamic> babyMap) async {
    await _prefs.setString(_selectedBabyKey, jsonEncode(babyMap));
  }

  /// Retrieve cached selected baby metadata.
  Map<String, dynamic>? getCachedSelectedBaby() {
    final jsonStr = _prefs.getString(_selectedBabyKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cache list of telemetry history items for a baby.
  Future<void> cacheTelemetryHistory(
    String babyId,
    List<Map<String, dynamic>> historyJsonList,
  ) async {
    final key = '$_telemetryHistoryCacheKeyPrefix$babyId';
    await _prefs.setString(key, jsonEncode(historyJsonList));
  }

  /// Retrieve cached list of telemetry history items for a baby.
  List<Map<String, dynamic>> getCachedTelemetryHistory(String babyId) {
    final key = '$_telemetryHistoryCacheKeyPrefix$babyId';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static const String _caregiverGrantedSessionKey = 'maatriva_caregiver_granted_session';

  /// Save caregiver granted active session metadata (retained across logouts until expired/revoked)
  Future<void> cacheCaregiverGrantedSession(Map<String, dynamic> sessionData) async {
    await _prefs.setString(_caregiverGrantedSessionKey, jsonEncode(sessionData));
  }

  /// Retrieve cached caregiver granted active session metadata
  Map<String, dynamic>? getCaregiverGrantedSession() {
    final jsonStr = _prefs.getString(_caregiverGrantedSessionKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear caregiver granted active session metadata when expired or revoked
  Future<void> clearCaregiverGrantedSession() async {
    await _prefs.remove(_caregiverGrantedSessionKey);
  }

  /// Clears cache completely on logout or account switch.
  Future<void> clearCache() async {
    try {
      await _prefs.clear();
    } catch (_) {}
  }
}
