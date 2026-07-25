import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../shared/models/user_session.dart';

/// Concrete implementation of [AuthRepository] managing user login/register requests and session caching.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final CacheService _cacheService;

  const AuthRepositoryImpl({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _cacheService = cacheService;

  @override
  Future<UserSession> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'parent',
  }) async {
    try {
      final res = await _apiClient.post(
        '/auth/register',
        body: {
          'fullName': '$firstName $lastName'.trim(),
          'email': email,
          'password': password,
          'role': role.toUpperCase(), // backend enum uses UPPERCASE
        },
        requireAuth: false,
      );

      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      final accessToken = dataMap['accessToken'] as String;
      final refreshToken = dataMap['refreshToken'] as String;
      final rawUserMap = dataMap['user'] as Map<String, dynamic>;
      final userId = rawUserMap['id'] as String;
      final userRole = rawUserMap['role'] as String;

      await _secureStorage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        userRole: userRole,
      );

      final userMap = Map<String, dynamic>.from(rawUserMap);
      userMap['role'] = userRole.toLowerCase();

      return UserSession.fromJson(userMap);
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      print('AuthRepositoryImpl.register caught error: $e');
      print(stack);
      throw ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable. Error: $e',
      );
    }
  }

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );

      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      final accessToken = dataMap['accessToken'] as String;
      final refreshToken = dataMap['refreshToken'] as String;
      final rawUserMap = dataMap['user'] as Map<String, dynamic>;
      final userId = rawUserMap['id'] as String;
      final userRole = rawUserMap['role'] as String;

      await _secureStorage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        userRole: userRole,
      );

      // Make a local copy of userMap with lowercase role to match parsing logic
      final userMap = Map<String, dynamic>.from(rawUserMap);
      userMap['role'] = userRole.toLowerCase();

      return UserSession.fromJson(userMap);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<void> logout() async {
    // Fire the network logout request in the background (do not await it)
    // so that local session teardown completes instantly without waiting for timeouts.
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        _apiClient.post(
          '/auth/logout',
          body: {
            'refreshToken': refreshToken,
          },
          requireAuth: true,
        ).catchError((_) {}); // catch background request errors
      }
    } catch (_) {
    } finally {
      await _cacheService.clearCache(); // Wipes SharedPreferences cache
      await _secureStorage.clearSession(); // Wipes Secure Storage tokens
    }
  }

  @override
  Future<bool> isUserLoggedIn() async {
    final token = await _secureStorage.getAccessToken();
    return token != null;
  }
}
