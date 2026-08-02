import 'api_config.dart';

export 'api_config.dart' show AppEnv;

class AppConfig {
  static AppEnv get environment => ApiConfig.environment;
  
  static void setEnvironment(AppEnv env) {
    ApiConfig.setEnvironment(env);
  }

  static String get apiBaseUrl => ApiConfig.baseUrl;
  static String get devBaseUrl => ApiConfig.baseUrl;
  static String get defaultDevIp => ApiConfig.baseUrl;

  static String get wsBaseUrl => ApiConfig.wsBaseUrl;

  static const String apiVersion = ApiConfig.apiVersion;
  
  static const int connectTimeout = ApiConfig.connectTimeout;
  static const int receiveTimeout = ApiConfig.receiveTimeout;
  static const int sendTimeout = ApiConfig.sendTimeout;
  
  static bool get isTesting => ApiConfig.isTesting;
  static set isTesting(bool val) => ApiConfig.isTesting = val;
}
