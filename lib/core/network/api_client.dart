import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage_service.dart';
import 'network_diagnostic.dart';

/// Interceptor that appends JWT token credentials to authorized request headers.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final requireAuth = options.extra['requireAuth'] ?? true;
    if (requireAuth) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return super.onRequest(options, handler);
  }
}

/// Interceptor that handles 401 Session Expiration errors, fetches renewed token, and replays requests.
class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  RefreshTokenInterceptor(this._dio, this._secureStorage);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final responseBody = err.response?.data.toString().toLowerCase() ?? '';
    final isAuthError = err.response?.statusCode == 401 ||
        (err.response?.statusCode == 403 &&
            (responseBody.contains('token expired') || responseBody.contains('jwt')));

    if (isAuthError) {
      final requestOptions = err.requestOptions;
      // Prevent infinite loops on auth specific paths
      if (requestOptions.path.contains('/auth/login') ||
          requestOptions.path.contains('/auth/refresh')) {
        return super.onError(err, handler);
      }

      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Dedicated Dio clone to bypass interceptors during token update
          final refreshDio = Dio(BaseOptions(
            baseUrl: _dio.options.baseUrl,
            connectTimeout: _dio.options.connectTimeout,
            receiveTimeout: _dio.options.receiveTimeout,
          ))..httpClientAdapter = _dio.httpClientAdapter;

          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final dynamic responseData = response.data;
            final Map<String, dynamic> responseMap = responseData is Map<String, dynamic>
                ? responseData
                : (responseData is String
                    ? jsonDecode(responseData) as Map<String, dynamic>
                    : Map<String, dynamic>.from(responseData as Map));

            String? newAccessToken;
            String? newRefreshToken;

            if (responseMap.containsKey('data') && responseMap['data'] is Map) {
              final dataMap = responseMap['data'] as Map;
              newAccessToken = dataMap['accessToken'] as String? ?? dataMap['token'] as String?;
              newRefreshToken = dataMap['refreshToken'] as String? ?? refreshToken;
            } else {
              newAccessToken = responseMap['accessToken'] as String? ?? responseMap['token'] as String?;
              newRefreshToken = responseMap['refreshToken'] as String? ?? refreshToken;
            }

            if (newAccessToken == null) {
              throw Exception('No access token found in refresh response');
            }
            
            final userId = await _secureStorage.getUserId() ?? '';
            final userRole = await _secureStorage.getUserRole() ?? 'PARENT';

            await _secureStorage.saveSession(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
              userId: userId,
              userRole: userRole,
            );

            // Re-auth request headers
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            
            // Replay cloned network query
            final responseCloned = await _dio.request(
              requestOptions.path,
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
            );
            return handler.resolve(responseCloned);
          }
        } catch (_) {
          await _secureStorage.clearSession();
        }
      }
    }
    return super.onError(err, handler);
  }
}

/// Helper Interceptor that prints logs for all HTTP requests, responses, and errors in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> [HTTP REQUEST] ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('Body: ${options.data}');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- [HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- [HTTP ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('Type: ${err.type}');
      debugPrint('Message: ${err.message}');
    }
    return super.onError(err, handler);
  }
}

/// Secure network provider linking HTTP queries to Cloud Backend using Dio.
class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _backendInitialized = false;

  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    _backendInitialized = false; // Force recheck health of the new endpoint
  }

  ApiClient({
    required String baseUrl,
    required SecureStorageService secureStorage,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl.isNotEmpty ? baseUrl : ApiConfig.baseUrl;
    _dio.options.connectTimeout = Duration(milliseconds: ApiConfig.connectTimeout);
    _dio.options.receiveTimeout = Duration(milliseconds: ApiConfig.receiveTimeout);
    _dio.options.sendTimeout = Duration(milliseconds: ApiConfig.sendTimeout);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.addAll([
      AuthInterceptor(_secureStorage),
      RefreshTokenInterceptor(_dio, _secureStorage),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  Future<void> ensureBackendReady() async {
    if (_backendInitialized || ApiConfig.isTesting) {
      _backendInitialized = true;
      return;
    }

    try {
      final response = await _dio.get(
        '/health',
        options: Options(extra: {'requireAuth': false}),
      );
      if (response.statusCode == 200) {
        _backendInitialized = true;
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Network] Primary backend health check failed at ${_dio.options.baseUrl}: $e');
      }
    }

    // Auto-discover working endpoint among local development candidates (USB debugging / Emulator / LAN)
    final currentBase = _dio.options.baseUrl;
    final candidates = <String>{
      ApiConfig.baseUrl,
      'http://192.168.1.33:3000',
      'http://127.0.0.1:3000',
      'http://10.0.2.2:3000',
      'http://localhost:3000',
    }.where((s) => s.trim().isNotEmpty).toList();

    for (final candidate in candidates) {
      if (candidate == currentBase) continue;
      try {
        if (kDebugMode) {
          debugPrint('[Network] Attempting fallback health check at $candidate...');
        }
        final testDio = Dio(BaseOptions(
          baseUrl: candidate,
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
        ));
        final res = await testDio.get('/health');
        if (res.statusCode == 200) {
          debugPrint('[Network] ✓ Discovered reachable backend server at $candidate!');
          setBaseUrl(candidate);
          ApiConfig.setCustomBaseUrl(candidate);
          _backendInitialized = true;
          return;
        }
      } catch (_) {}
    }

    _backendInitialized = true; // Mark initialized to avoid blocking auth calls permanently
  }

  Future<dynamic> get(
    String path, {
    bool requireAuth = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      if (path != '/health') {
        await ensureBackendReady();
      }
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      if (path != '/health') {
        await ensureBackendReady();
      }
      final response = await _dio.post(
        path,
        data: body,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      if (path != '/health') {
        await ensureBackendReady();
      }
      final response = await _dio.put(
        path,
        data: body,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      if (path != '/health') {
        await ensureBackendReady();
      }
      final response = await _dio.patch(
        path,
        data: body,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    bool requireAuth = true,
  }) async {
    try {
      if (path != '/health') {
        await ensureBackendReady();
      }
      final response = await _dio.delete(
        path,
        options: Options(extra: {'requireAuth': requireAuth}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.error.toString().contains('SocketException') ||
        err.error.toString().contains('Connection refused')) {
      _backendInitialized = false; // Reset so next request re-discovers active backend server
    }
    if (kDebugMode) {
      debugPrint('ApiClient._handleDioError: type=${err.type}, message=${err.message}');
    }
    final diagnostic = NetworkDiagnostic.diagnoseDioError(err);
    return ApiException(
      statusCode: diagnostic.statusCode ?? 0,
      message: diagnostic.message,
    );
  }
}
