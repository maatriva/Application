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
      _customBaseUrl = sanitizeApiUrl(url);
    }
  }

  /// Compile-time build configuration via --dart-define=API_BASE_URL=... (or --dart-define=API_URL=...)
  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment('API_URL'),
  );

  static const String devWebBaseUrl = 'http://localhost:3000/api';
  static const String devAndroidEmulatorBaseUrl = 'http://10.0.2.2:3000/api';
  static const String stagingBaseUrl = 'https://staging-api.maatriva.cloud/api';
  static const String prodBaseUrl = 'https://api.maatriva.co.in/api';

  /// Sanitizes and validates any API base URL string.
  /// Ensures valid HTTP/HTTPS scheme, strips trailing slashes, and guarantees a single /api path suffix.
  static String sanitizeApiUrl(String input) {
    String formatted = input.trim();
    if (formatted.isEmpty) return '';

    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }

    // Strip trailing slashes
    formatted = formatted.replaceAll(RegExp(r'/+$'), '');

    // Prevent double /api/api
    if (formatted.endsWith('/api/api')) {
      formatted = formatted.substring(0, formatted.length - 4);
    } else if (!formatted.endsWith('/api')) {
      formatted = '$formatted/api';
    }

    return formatted;
  }

  /// Automatically selects the correct base URL based on platform and build mode.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return sanitizeApiUrl(_customBaseUrl!);
    }
    if (_envApiBaseUrl.isNotEmpty) {
      return sanitizeApiUrl(_envApiBaseUrl);
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
        if (defaultTargetPlatform == TargetPlatform.android) {
          return devAndroidEmulatorBaseUrl;
        }
        return devWebBaseUrl;
    }
  }

  /// Automatically derives the WebSocket URL from the base HTTP URL.
  static String get wsBaseUrl {
    final httpUrl = baseUrl.replaceAll(RegExp(r'/api$'), '');
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

    String raw = inputUrl.trim();

    // Data URLs, Blob URLs, or explicit assets/ paths shouldn't be prepended with http://...
    if (raw.startsWith('data:') ||
        raw.startsWith('blob:') ||
        raw.startsWith('assets/')) {
      return raw;
    }

    final serverBase = baseUrl.replaceAll(RegExp(r'/+$'), '').replaceAll(RegExp(r'/api$'), '');

    if (raw.startsWith('audio/')) {
      final filename = raw.substring(6);
      return '$serverBase/uploads/music/$filename';
    }

    if (raw.startsWith('http:///') || raw.startsWith('https:///')) {
      raw = raw.replaceFirst(RegExp(r'^https?:///'), '/');
    }

    // 2. Relative paths (e.g. /uploads/music/file.mp3 or uploads/music/file.mp3)
    if (raw.startsWith('/') || raw.startsWith('uploads/') || raw.startsWith('api/')) {
      final cleanPath = raw.startsWith('/') ? raw : '/$raw';
      return '$serverBase$cleanPath';
    }

    // 3. Absolute URLs or domain paths
    String server = raw;
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      if (!server.contains('.')) {
        final cleanPath = server.startsWith('/') ? server : '/$server';
        final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
        return '$cleanBase$cleanPath';
      }
      server = 'http://$server';
    }

    // 4. Sanitize localhost / 127.0.0.1 / 10.0.2.2 for mobile & web
    final uri = Uri.tryParse(server);
    if (uri != null && uri.hasAuthority) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
        final currentBaseUri = Uri.tryParse(baseUrl);
        if (currentBaseUri != null && currentBaseUri.hasAuthority) {
          return uri.replace(
            scheme: currentBaseUri.scheme,
            host: currentBaseUri.host,
            port: currentBaseUri.port,
          ).toString();
        }
        return baseUrl;
      }
      return server;
    }

    if (server.contains('localhost') || server.contains('127.0.0.1') || server.contains('10.0.2.2')) {
      return baseUrl;
    }

    return server;
  }

  static bool isTesting = false;
}
