import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maatriva/core/models/models.dart';
import 'package:maatriva/core/network/api_client.dart';
import 'package:maatriva/core/network/websocket_service.dart';
import 'package:maatriva/core/services/secure_storage_service.dart';
import 'package:maatriva/core/services/cache_service.dart';
import 'package:maatriva/core/repositories/auth_repository.dart';
import 'package:maatriva/core/repositories/device_repository.dart';

// Hand-written Mock for FlutterSecureStorage implementing the interface
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Hand-written Mock HTTP client
class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) requestHandler;

  MockHttpClient(this.requestHandler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await requestHandler(request);
    final bodyBytes = response.bodyBytes;
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      response.statusCode,
      headers: response.headers,
      contentLength: bodyBytes.length,
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockSecureStorage mockSecureStorage;
  late SecureStorageService secureStorageService;
  late SharedPreferences mockPrefs;
  late CacheService cacheService;

  setUp(() async {
    mockSecureStorage = MockSecureStorage();
    secureStorageService = SecureStorageService(storage: mockSecureStorage);

    mockPrefs = await SharedPreferences.getInstance();
    cacheService = CacheService(mockPrefs);
  });

  group('SecureStorageService Tests', () {
    test('saveSession writes keys correctly', () async {
      await secureStorageService.saveSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_123',
        userId: 'u_1',
        userRole: 'parent',
      );

      expect(await secureStorageService.getAccessToken(), 'access_123');
      expect(await secureStorageService.getRefreshToken(), 'refresh_123');
      expect(await secureStorageService.getUserId(), 'u_1');
      expect(await secureStorageService.getUserRole(), 'parent');
    });

    test('clearSession removes keys', () async {
      await secureStorageService.saveSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_123',
        userId: 'u_1',
        userRole: 'parent',
      );
      await secureStorageService.clearSession();

      expect(await secureStorageService.getAccessToken(), isNull);
    });
  });

  group('ApiClient REST Interceptor & Token Refresh Tests', () {
    test('Successful REST request includes Authorization headers', () async {
      await secureStorageService.saveSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_123',
        userId: 'u_1',
        userRole: 'parent',
      );

      final mockHttp = MockHttpClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access_123');
        return http.Response(jsonEncode({'id': 'b1', 'name': 'Baby Liam'}), 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: mockHttp,
        secureStorage: secureStorageService,
      );

      final result = await apiClient.get('/babies/b1');
      expect(result['name'], 'Baby Liam');
    });

    test('Expired access token triggers refresh token interceptor flow', () async {
      await secureStorageService.saveSession(
        accessToken: 'expired_access_123',
        refreshToken: 'valid_refresh_123',
        userId: 'u_1',
        userRole: 'parent',
      );

      var requestCount = 0;
      final mockHttp = MockHttpClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // First attempt: return 401 Unauthorized
          expect(request.url.path, '/babies/b1');
          return http.Response('{"error": "Unauthorized"}', 401);
        } else if (requestCount == 2) {
          // Second request: Token refresh invocation
          expect(request.url.path, '/auth/refresh');
          final body = jsonDecode((request as http.Request).body);
          expect(body['refreshToken'], 'valid_refresh_123');
          return http.Response(jsonEncode({
            'token': 'renewed_access_999',
            'refreshToken': 'valid_refresh_123',
            'user': {'id': 'u_1', 'role': 'parent'}
          }), 200);
        } else {
          // Third request: Replay original request with new token
          expect(request.url.path, '/babies/b1');
          expect(request.headers['Authorization'], 'Bearer renewed_access_999');
          return http.Response(jsonEncode({'id': 'b1', 'name': 'Liam'}), 200);
        }
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: mockHttp,
        secureStorage: secureStorageService,
      );

      final result = await apiClient.get('/babies/b1');
      expect(result['name'], 'Liam');
      expect(await secureStorageService.getAccessToken(), 'renewed_access_999');
    });
  });

  group('DeviceRepository Offline Caching Fallback Tests', () {
    test('Offline vitals query triggers shared preferences cache retrieval', () async {
      final cachedTelemetryMap = {
        'heart_rate': {
          'sensorType': 'heart_rate',
          'value': 125.0,
          'unit': 'bpm',
          'quality': 'good',
          'timestamp': '2026-07-21T12:00:00.000Z'
        }
      };
      await cacheService.cacheVitals('ESP32-948210', cachedTelemetryMap);

      // Setup HTTP Client to simulate networking failure
      final mockHttp = MockHttpClient((request) async {
        throw Exception('Network unreachable');
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: mockHttp,
        secureStorage: secureStorageService,
      );

      final repository = DeviceRepository(
        apiClient: apiClient,
        cacheService: cacheService,
      );

      final vitals = await repository.getLatestTelemetry('ESP32-948210');
      expect(vitals.length, 1);
      expect(vitals[0].sensorType, 'heart_rate');
      expect(vitals[0].value, 125.0);
    });
  });
}
