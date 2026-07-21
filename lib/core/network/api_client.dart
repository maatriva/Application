import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/secure_storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

/// Secure, interceptor-aware HTTP API client connecting exclusively to the Cloud Backend.
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final SecureStorageService _secureStorage;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    required SecureStorageService secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage;

  /// Helper to compose standard headers with JWT tokens.
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Sends a GET request.
  Future<dynamic> get(String path, {bool requireAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _requestWithRetry(
      () async => _client.get(uri, headers: await _getHeaders(requireAuth: requireAuth)),
      path,
      requireAuth,
    );
    return _parseResponse(response);
  }

  /// Sends a POST request.
  Future<dynamic> post(String path, {dynamic body, bool requireAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _requestWithRetry(
      () async => _client.post(
        uri,
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      path,
      requireAuth,
    );
    return _parseResponse(response);
  }

  /// Sends a PATCH request.
  Future<dynamic> patch(String path, {dynamic body, bool requireAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _requestWithRetry(
      () async => _client.patch(
        uri,
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      path,
      requireAuth,
    );
    return _parseResponse(response);
  }

  /// Sends a DELETE request.
  Future<dynamic> delete(String path, {bool requireAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _requestWithRetry(
      () async => _client.delete(uri, headers: await _getHeaders(requireAuth: requireAuth)),
      path,
      requireAuth,
    );
    return _parseResponse(response);
  }

  /// Orchestrates HTTP call, intercepts 401, attempts JWT Refresh, and replays request.
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn,
    String path,
    bool requireAuth,
  ) async {
    var response = await requestFn();

    if (response.statusCode == 401 && requireAuth && path != '/auth/refresh' && path != '/auth/login') {
      // 401 Unauthorized: Attempt token refresh
      final refreshSuccess = await _attemptTokenRefresh();
      if (refreshSuccess) {
        // Replay request with renewed token
        response = await requestFn();
      } else {
        // Refresh failed: clear storage and throw
        await _secureStorage.clearSession();
        throw const ApiException(statusCode: 401, message: 'Session expired. Please log in again.');
      }
    }

    return response;
  }

  /// Hits refresh endpoint to update tokens.
  Future<bool> _attemptTokenRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final res = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _secureStorage.saveSession(
          accessToken: data['token'] as String,
          refreshToken: data['refreshToken'] as String? ?? refreshToken,
          userId: data['user']?['id'] as String? ?? '',
          userRole: data['user']?['role'] as String? ?? 'caregiver',
        );
        return true;
      }
    } catch (_) {
      // Network failure
    }
    return false;
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      Map<String, dynamic>? errBody;
      try {
        errBody = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      throw ApiException(
        statusCode: response.statusCode,
        message: errBody?['error'] as String? ?? 'An HTTP network error occurred.',
      );
    }
  }
}
