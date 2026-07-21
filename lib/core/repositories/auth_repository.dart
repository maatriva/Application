import '../models/models.dart';
import '../network/api_client.dart';
import '../services/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  const AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  /// Registers caregiver user.
  Future<UserSession> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'caregiver',
  }) async {
    final res = await _apiClient.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      },
      requireAuth: false,
    );
    return UserSession.fromJson(res as Map<String, dynamic>);
  }

  /// Logs user in and registers the JWT session tokens to secure storage.
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requireAuth: false,
    );

    final data = res as Map<String, dynamic>;
    final accessToken = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;
    final userId = userMap['id'] as String;
    final userRole = userMap['role'] as String;

    // Save token credentials
    await _secureStorage.saveSession(
      accessToken: accessToken,
      refreshToken: accessToken, // using access token as mock refresh for MVP
      userId: userId,
      userRole: userRole,
    );

    return UserSession.fromJson(userMap);
  }

  /// Logs user out and deletes JWT token credentials cache.
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout', requireAuth: true);
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _secureStorage.clearSession();
    }
  }

  /// Checks if there is an active session cache.
  Future<bool> isUserLoggedIn() async {
    final token = await _secureStorage.getAccessToken();
    return token != null;
  }
}
