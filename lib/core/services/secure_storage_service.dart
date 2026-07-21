import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing secure storage for cryptographic keys and authentication tokens.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String _accessTokenKey = 'maatriva_access_token';
  static const String _refreshTokenKey = 'maatriva_refresh_token';
  static const String _userIdKey = 'maatriva_user_id';
  static const String _userRoleKey = 'maatriva_user_role';

  /// Save JWT tokens and session data.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: userRole),
    ]);
  }

  /// Get the active access token.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get the active refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get the logged-in user's ID.
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get the logged-in user's role.
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  /// Clears the token store on logout or session expiration.
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userRoleKey),
    ]);
  }
}
