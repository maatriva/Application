import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing secure storage for cryptographic keys and authentication tokens.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static String? _cachedUserId;
  static String? _cachedUserRole;
  static String? _cachedUserEmail;

  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String _accessTokenKey = 'maatriva_access_token';
  static const String _refreshTokenKey = 'maatriva_refresh_token';
  static const String _userIdKey = 'maatriva_user_id';
  static const String _userRoleKey = 'maatriva_user_role';
  static const String _userEmailKey = 'maatriva_user_email';

  /// Save JWT tokens and session data.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
    String? userEmail,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedUserId = userId;
    _cachedUserRole = userRole;
    if (userEmail != null) _cachedUserEmail = userEmail;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: userRole),
      if (userEmail != null) _storage.write(key: _userEmailKey, value: userEmail),
    ]);
  }

  /// Get the active access token.
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    final token = await _storage.read(key: _accessTokenKey);
    _cachedAccessToken = token;
    return token;
  }

  /// Get the active refresh token.
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    final token = await _storage.read(key: _refreshTokenKey);
    _cachedRefreshToken = token;
    return token;
  }

  /// Get the logged-in user's ID.
  Future<String?> getUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId;
    }
    final id = await _storage.read(key: _userIdKey);
    _cachedUserId = id;
    return id;
  }

  /// Get the logged-in user's role.
  Future<String?> getUserRole() async {
    if (_cachedUserRole != null && _cachedUserRole!.isNotEmpty) {
      return _cachedUserRole;
    }
    final role = await _storage.read(key: _userRoleKey);
    _cachedUserRole = role;
    return role;
  }

  /// Get the logged-in user's email.
  Future<String?> getUserEmail() async {
    if (_cachedUserEmail != null && _cachedUserEmail!.isNotEmpty) {
      return _cachedUserEmail;
    }
    final email = await _storage.read(key: _userEmailKey);
    _cachedUserEmail = email;
    return email;
  }

  /// Clears the token store on logout or session expiration.
  Future<void> clearSession() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserId = null;
    _cachedUserRole = null;
    _cachedUserEmail = null;

    try {
      await _storage.deleteAll();
    } catch (_) {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userRoleKey),
        _storage.delete(key: _userEmailKey),
      ]);
    }
  }
}
