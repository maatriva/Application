import 'package:flutter/foundation.dart';

enum AppEnv { dev, staging, prod }

class ApiConfig {
  static AppEnv _environment = kReleaseMode ? AppEnv.prod : AppEnv.dev;

  static AppEnv get environment => _environment;
  static void setEnvironment(AppEnv env) {
    _environment = env;
  }

  /// Custom base URL override set dynamically at runtime (e.g. settings UI / diagnostics)
  static String? _customBaseUrl;

  static String? get customBaseUrl => _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
    } else {
      String formatted = url.trim();
      if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
        formatted = 'http://$formatted';
      }
      _customBaseUrl = formatted;
    }
  }

  /// Optional compile-time override: flutter run --dart-define=API_URL=http://192.168.1.50:3000
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _defaultLanIp = 'http://10.63.127.227:3000';

  static const String devWebBaseUrl = 'http://localhost:3000';
  static const String devAndroidEmulatorBaseUrl = 'http://10.0.2.2:3000';
  static const String stagingBaseUrl = 'https://staging-api.maatriva.cloud';
  static const String prodBaseUrl = 'https://api.maatriva.co.in';

  /// Automatically selects the correct base URL based on platform and build mode.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }

    switch (_environment) {
      case AppEnv.staging:
        return stagingBaseUrl;
      case AppEnv.prod:
        return prodBaseUrl;
      case AppEnv.dev:
        if (kIsWeb) {
          return devWebBaseUrl;
        }
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) {
          // Defaults to physical host Wi-Fi IP so real devices on local network can connect
          return _defaultLanIp;
        }
        return devWebBaseUrl;
    }
  }

  /// Automatically derives the WebSocket URL from the base HTTP URL.
  static String get wsBaseUrl {
    final httpUrl = baseUrl;
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    } else if (httpUrl.startsWith('http://')) {
      return httpUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://localhost:3000';
  }

  static const String apiVersion = 'v1';

  // 15-second timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int sendTimeout = 15000;

  /// Resolves and sanitizes a QR code server URL for the current client platform.
  /// If the QR server points to a local dev address (localhost, 127.0.0.1, 10.0.2.2),
  /// it returns the platform-appropriate ApiConfig.baseUrl for this client.
  static String resolveServerUrl(String? inputUrl) {
    if (inputUrl == null || inputUrl.trim().isEmpty) {
      return baseUrl;
    }

    String server = inputUrl.trim();
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      server = 'http://$server';
    }

    final uri = Uri.tryParse(server);
    if (uri != null && uri.hasAuthority) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
        return baseUrl;
      }
      return server;
    }

    // Fallback for malformed URLs
    if (server.contains('localhost') || server.contains('127.0.0.1') || server.contains('10.0.2.2')) {
      return baseUrl;
    }

    return server;
  }

  static bool isTesting = false;
}
