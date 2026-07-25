import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Storage services
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/cache_service.dart';
import '../storage/secure_storage_service.dart';

// Core Services
import 'iot_device_repository.dart';
import 'websocket_service.dart';

// Domain Repositories
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/baby_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/repositories/caregiver_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../../domain/repositories/ai_repository.dart';

// Data Repositories Implementations
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/baby_repository_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../data/repositories/caregiver_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/monitoring_repository_impl.dart';
import '../../data/repositories/telemetry_repository_impl.dart';
import '../../data/repositories/ai_repository_impl.dart';

// Authentication Providers
import '../../features/authentication/presentation/providers/auth_provider.dart';

// Global ScaffoldMessengerState Key
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// SharedPreferences provider (overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

// SecureStorage provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

// CacheService provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
});

// ApiClient provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    secureStorage: secureStorage,
  );
});

// WebSocketService provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final service = WebSocketService(
    wsBaseUrl: AppConfig.wsBaseUrl,
    secureStorage: secureStorage,
  );

  final authState = ref.read(authNotifierProvider);
  if (authState.status == AuthStatus.authenticated) {
    service.connect();
  }

  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      service.connect();
    } else if (next.status == AuthStatus.unauthenticated) {
      service.setSelectedBaby(null);
      service.disconnect();
    }
  });

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// IotDeviceRepository provider
final iotDeviceRepositoryProvider = Provider<IotDeviceRepository>((ref) {
  final ws = ref.watch(webSocketServiceProvider);
  return IotDeviceRepository(webSocketService: ws);
});

// AuthRepository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final cache = ref.watch(cacheServiceProvider);
  return AuthRepositoryImpl(
    apiClient: client,
    secureStorage: secureStorage,
    cacheService: cache,
  );
});

// BabyRepository provider
final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BabyRepositoryImpl(apiClient: client);
});

// DeviceRepository provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return DeviceRepositoryImpl(apiClient: client, cacheService: cache);
});

// TelemetryRepository provider
final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return TelemetryRepositoryImpl(apiClient: client, cacheService: cache);
});

// AlertRepository provider
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AlertRepositoryImpl(apiClient: client);
});

// CaregiverRepository provider
final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return CaregiverRepositoryImpl(apiClient: client, cacheService: cache);
});

// ProfileRepository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final cache = ref.watch(cacheServiceProvider);
  return ProfileRepositoryImpl(apiClient: client, cacheService: cache);
});

// MonitoringRepository provider
final monitoringRepositoryProvider = Provider<MonitoringRepository>((ref) {
  final iot = ref.watch(iotDeviceRepositoryProvider);
  final ws = ref.watch(webSocketServiceProvider);
  return MonitoringRepositoryImpl(iotDeviceRepository: iot, webSocketService: ws);
});

// AiRepository provider
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AiRepositoryImpl(apiClient: client);
});
