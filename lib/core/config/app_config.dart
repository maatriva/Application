import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppEnv { dev, staging, prod }

class AppConfig {
  // Switch this to AppEnv.staging or AppEnv.prod for Staging/Production environments
  static const AppEnv environment = AppEnv.dev;

  static const String devBaseUrl = 'http://localhost:3000';
  static const String devAndroidEmulatorBaseUrl = 'http://10.0.2.2:3000';
  
  static const String stagingBaseUrl = 'https://staging-api.maatriva.cloud';
  static const String prodBaseUrl = 'https://api.maatriva.co.in';

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnv.dev:
        if (!kIsWeb && Platform.isAndroid) {
          return devAndroidEmulatorBaseUrl;
        }
        return devBaseUrl;
      case AppEnv.staging:
        return stagingBaseUrl;
      case AppEnv.prod:
        return prodBaseUrl;
    }
  }

  static String get wsBaseUrl {
    final httpUrl = apiBaseUrl;
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    } else {
      return httpUrl.replaceFirst('http://', 'ws://');
    }
  }

  static const String apiVersion = 'v1';
  
  // 10-second timeouts as requested
  static const int connectTimeout = 30000; // 30s
  static const int receiveTimeout = 30000; // 30s
  static const int sendTimeout = 30000; // 30s
  
  static bool isTesting = false;
}
