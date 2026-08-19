import 'package:flutter_test/flutter_test.dart';
import 'package:maatriva/core/config/api_config.dart';

void main() {
  group('ApiConfig Environment & URL Sanitization Tests', () {
    tearDown(() {
      ApiConfig.setEnvironment(AppEnv.dev);
      ApiConfig.setCustomBaseUrl(null);
    });

    test('sanitizeApiUrl formats schemes and guarantees single /api suffix', () {
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.50:3000'), equals('http://192.168.1.50:3000/api'));
      expect(ApiConfig.sanitizeApiUrl('192.168.1.50:3000'), equals('http://192.168.1.50:3000/api'));
      expect(ApiConfig.sanitizeApiUrl('http://localhost:3000/api/'), equals('http://localhost:3000/api'));
      expect(ApiConfig.sanitizeApiUrl('http://localhost:3000/api/api'), equals('http://localhost:3000/api'));
      expect(ApiConfig.sanitizeApiUrl('https://api.maatriva.co.in'), equals('https://api.maatriva.co.in/api'));
    });

    test('customBaseUrl override takes precedence and is sanitized', () {
      ApiConfig.setCustomBaseUrl('http://192.168.1.100:3000');
      expect(ApiConfig.baseUrl, equals('http://192.168.1.100:3000/api'));

      ApiConfig.setCustomBaseUrl(null);
      expect(ApiConfig.baseUrl, isNot(equals('http://192.168.1.100:3000/api')));
    });

    test('AppEnv.prod resolves production base URL', () {
      ApiConfig.setEnvironment(AppEnv.prod);
      expect(ApiConfig.baseUrl, equals('https://api.maatriva.co.in/api'));
    });

    test('AppEnv.staging resolves staging base URL', () {
      ApiConfig.setEnvironment(AppEnv.staging);
      expect(ApiConfig.baseUrl, equals('https://staging-api.maatriva.cloud/api'));
    });

    test('resolveServerUrl converts relative media paths correctly without duplicate /api', () {
      ApiConfig.setEnvironment(AppEnv.dev);
      final audioUrl = ApiConfig.resolveServerUrl('audio/lullaby.mp3');
      expect(audioUrl, contains('/uploads/music/lullaby.mp3'));
      expect(audioUrl, isNot(contains('/api/uploads')));
    });
  });
}
