import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final requestBody = {
      'fullName': '$firstName $lastName'.trim(),
      'email': email,
      'password': password,
      'role': role.toUpperCase(),
    };

    debugPrint('[AUTH] Sending register request for $email...');
    try {
      final res = await _apiClient.post(
        '/auth/register',
        body: requestBody,
        requireAuth: false,
      );

      debugPrint('[AUTH] Register response received.');
      return await _processAuthResponse(res);
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AUTH] AuthRepositoryImpl.register caught error: $e\n$stack');
      }
      throw ApiException(
        statusCode: 0,
        message: 'Registration failed: Network connection issue.',
      );
    }
  }

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final requestBody = {
      'email': email,
      'password': password,
    };

    debugPrint('[AUTH] Sending login request for $email...');
    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: requestBody,
        requireAuth: false,
      );

      debugPrint('[AUTH] Login HTTP 200 response received.');
      return await _processAuthResponse(res);
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[AUTH] AuthRepositoryImpl.login caught error: $e\n$stack');
      }
      throw const ApiException(
        statusCode: 0,
        message: 'Unable to connect to server. Please check your network connection.',
      );
    }
  }

  Future<UserSession> _processAuthResponse(dynamic res) async {
    if (res == null || res is! Map) {
      throw const ApiException(
        statusCode: 0,
        message: 'Invalid response structure from authentication server.',
      );
    }

    final responseMap = Map<String, dynamic>.from(res as Map);
    Map<String, dynamic> dataMap = responseMap;
    if (responseMap.containsKey('data') && responseMap['data'] is Map) {
      dataMap = Map<String, dynamic>.from(responseMap['data'] as Map);
    }

    final accessToken = dataMap['accessToken'] as String? ?? dataMap['token'] as String?;
    final refreshToken = dataMap['refreshToken'] as String? ?? '';
    
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 0,
        message: 'Authentication token missing in server response.',
      );
    }

    Map<String, dynamic> rawUserMap = {};
    if (dataMap.containsKey('user') && dataMap['user'] is Map) {
      rawUserMap = Map<String, dynamic>.from(dataMap['user'] as Map);
    } else {
      rawUserMap = dataMap;
    }

    final userId = rawUserMap['id'] as String? ?? rawUserMap['_id'] as String? ?? dataMap['id'] as String? ?? '';
    final userRole = rawUserMap['role'] as String? ??
        rawUserMap['userRole'] as String? ??
        dataMap['role'] as String? ??
        dataMap['userRole'] as String? ??
        responseMap['role'] as String? ??
        'PARENT';
    final email = rawUserMap['email'] as String? ?? dataMap['email'] as String? ?? '';

    debugPrint('[TOKEN] Saving session tokens: userId=$userId, role=$userRole, email=$email');
    await _secureStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userRole: userRole,
      userEmail: email,
    );
    debugPrint('[TOKEN] Session tokens saved successfully to secure storage.');

    final userMap = Map<String, dynamic>.from(rawUserMap);
    userMap['id'] = userId;
    userMap['email'] = email;
    userMap['role'] = userRole;

    return UserSession.fromJson(userMap);
  }

  @override
  Future<void> logout() async {
    String? refreshToken;

    // Local sign-out must never wait for the server.  In particular, when the
    // device is offline a pending HTTP request used to keep the stored session
    // alive until it timed out.
    try {
      refreshToken = await _secureStorage.getRefreshToken();
      debugPrint('[AUTH REPO] Initiating signout request to /auth/logout (hasRefreshToken: ${refreshToken != null})');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // The access token is deliberately retained only long enough to send
        // this best-effort revocation request.  The local session is cleared
        // immediately below regardless of the request result.
        _apiClient.post(
          '/auth/logout',
          body: {
            'refreshToken': refreshToken,
          },
          requireAuth: true,
        ).then((_) {
          debugPrint('[AUTH REPO] POST /auth/logout network request delivered successfully.');
        }).catchError((e) {
          debugPrint('[AUTH REPO] Non-fatal network error during /auth/logout: $e');
        });
      } else {
        debugPrint('[AUTH REPO] No refresh token stored; skipping POST /auth/logout.');
      }
    } catch (e) {
      debugPrint('[AUTH REPO] Non-fatal network error during /auth/logout: $e');
    } finally {
      await Future.wait([
        _cacheService.clearCache(), // Wipes SharedPreferences cache
        _secureStorage.clearSession(), // Wipes Secure Storage tokens
      ]);
    }
  }

  @override
  Future<bool> isUserLoggedIn() async {
    final token = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    if (token == null || token.isEmpty) return false;

    final parts = token.split('.');
    if (parts.length == 3) {
      try {
        var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }
        final payloadString = utf8.decode(base64.decode(normalized));
        final decoded = jsonDecode(payloadString);
        if (decoded is Map && decoded['exp'] != null) {
          final expSecs = decoded['exp'] as int;
          final expDateTime = DateTime.fromMillisecondsSinceEpoch(expSecs * 1000, isUtc: true);
          final nowUtc = DateTime.now().toUtc();
          if (nowUtc.isAfter(expDateTime.subtract(const Duration(seconds: 10)))) {
            // Access token expired, user is logged in ONLY if a refresh token is present
            return refreshToken != null && refreshToken.isNotEmpty;
          }
        }
      } catch (_) {}
    }
    return true;
  }
}
