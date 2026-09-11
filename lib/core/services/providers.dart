import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Storage services
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/cache_service.dart';
import '../storage/secure_storage_service.dart';
import '../../shared/models/user_session.dart';

// Core Services
import 'iot_device_repository.dart';
import 'websocket_service.dart';
import 'webrtc_service.dart';

// Feature Providers
import '../../features/music/providers/music_provider.dart';


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
import '../../features/caregivers/provider/caregiver_access_provider.dart';

import '../../shared/widgets/caretaker_time_extended_dialog.dart';

// Global ScaffoldMessengerState Key & Root Navigator Key
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final rootNavigatorKey = GlobalKey<NavigatorState>();

final Set<String> _processedExtensionEvents = <String>{};

String _formatExtensionText(int mins) {
  if (mins <= 0) return 'additional time';
  if (mins % 1440 == 0) {
    final d = mins ~/ 1440;
    return d == 1 ? '1 day' : '$d days';
  }
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h == 0) {
    return '$m minute${m == 1 ? '' : 's'}';
  } else if (m == 0) {
    return '$h hour${h == 1 ? '' : 's'}';
  } else {
    return '$h hour${h == 1 ? '' : 's'} $m minute${m == 1 ? '' : 's'}';
  }
}

String _formatRemainingText(Duration diff) {
  if (diff.isNegative) return '0m';
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}

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

/// Reactive permission state for the active caregiver session. The server and
/// persisted session remain authoritative; this provider only lets widgets
/// rebuild as soon as a validated server event arrives.
final caregiverPermissionsProvider = StateProvider<Map<String, bool>>((ref) {
  final session = ref.watch(cacheServiceProvider).getCaregiverGrantedSession();
  final raw = session?['permissions'];
  if (raw is! Map) return {};
  return Map<String, bool>.from(raw.map((key, value) => MapEntry(key.toString(), value == true)));
});

/// Reactive session expiration timestamp for active caregiver session.
final caregiverSessionExpiryProvider = StateProvider<DateTime?>((ref) {
  final session = ref.watch(cacheServiceProvider).getCaregiverGrantedSession();
  final expiresAtStr = session?['expiresAt'] as String?;
  if (expiresAtStr == null) return null;
  return DateTime.tryParse(expiresAtStr);
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
final Provider<WebSocketService> webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final service = WebSocketService(
    wsBaseUrl: AppConfig.wsBaseUrl,
    secureStorage: secureStorage,
  );

  final authState = ref.read(authNotifierProvider);
  if (authState.status == AuthStatus.authenticated) {
    service.connect(force: true);
  }

  service.onSessionExpired = () {
    debugPrint('[Auth] Session expired (token refresh failed). Logging out user...');
    ref.read(authNotifierProvider.notifier).logout();
  };

  service.onAppResumed = () {
    debugPrint('[AppResume] App resumed. Re-verifying caregiver permissions...');
    ref.read(authNotifierProvider.notifier).verifyCaregiverActivePermissions(null, true).then((_) {
      final raw = ref.read(cacheServiceProvider).getCaregiverGrantedSession()?['permissions'];
      if (raw is Map) {
        ref.read(caregiverPermissionsProvider.notifier).state = Map<String, bool>.from(
          raw.map((key, value) => MapEntry(key.toString(), value == true)),
        );
      }
      debugPrint('[CaregiverPermissions] Resume synchronization completed.');
    });
  };

  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    if (previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated) {
      service.connect(force: true);
    } else if (next.status == AuthStatus.unauthenticated) {
      service.setSelectedBaby(null);
      service.disconnect();
      try {
        ref.read(webrtcServiceProvider.notifier).disconnectStream();
      } catch (_) {}
    }
  });

  service.caregiverRevokedStream.listen((msg) async {
    debugPrint('[CaregiverRevoked] Revocation or expiration event received. Clearing session & logging out...');
    final cache = ref.read(cacheServiceProvider);
    await cache.clearCaregiverGrantedSession();
    await cache.sharedPreferences.remove('maatriva_cache_selected_baby');
    await cache.sharedPreferences.remove('maatriva_cache_selected_baby_id');
    await cache.sharedPreferences.remove('maatriva_cache_selected_baby_name');
    await ref.read(authNotifierProvider.notifier).logout();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg.isNotEmpty ? msg : 'Your caregiver access has been revoked by the parent.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  });

  service.caregiverPermissionsUpdatedStream.listen((data) {
    final session = ref.read(authNotifierProvider).session;
    final currentUserId = session?.id;
    final isCaregiverRole = session?.role == UserRole.caregiver;
    final eventCaregiverId = data['caregiverId']?.toString();
    final permissions = data['permissions'];

    if (currentUserId == null || permissions is! Map) {
      debugPrint('[CaregiverPermissionsUpdated] Ignored invalid event payload or unauthenticated state.');
      return;
    }

    if (eventCaregiverId != null && eventCaregiverId.isNotEmpty && eventCaregiverId != currentUserId) {
      debugPrint('[CaregiverPermissionsUpdated] Ignored event targeting different caregiver user.');
      return;
    }

    final permissionMap = <String, bool>{
      'live_video': true,
      'health': true,
      'ai_monitoring': true,
      'ai_chatbot': true,
      'custom_parent_folder': true,
      'shop': true,
      'real_time_alerts': true,
    };
    permissions.forEach((k, v) {
      final keyStr = k.toString();
      final bool val = v == true || v == 'true' || v == 1;
      permissionMap[keyStr] = val;
      if (keyStr == 'live_video' || keyStr == 'liveVideo' || keyStr == 'camera_snapshot' || keyStr == 'camera' || keyStr == 'cameraSnapshot') {
        permissionMap['live_video'] = val;
      }
      if (keyStr == 'health' || keyStr == 'health_data' || keyStr == 'health_reports' || keyStr == 'healthData' || keyStr == 'telemetry') {
        permissionMap['health'] = val;
      }
      if (keyStr == 'ai_monitoring' || keyStr == 'aiMonitoring' || keyStr == 'ai') {
        permissionMap['ai_monitoring'] = val;
      }
      if (keyStr == 'ai_chatbot' || keyStr == 'aiChatbot' || keyStr == 'ai_assistant' || keyStr == 'aiAssistant') {
        permissionMap['ai_chatbot'] = val;
      }
      if (keyStr == 'custom_parent_folder' || keyStr == 'customParentFolder' || keyStr == 'custom_music' || keyStr == 'customMusic' || keyStr == 'music') {
        permissionMap['custom_parent_folder'] = val;
      }
      if (keyStr == 'shop' || keyStr == 'shopAccess' || keyStr == 'canViewShop' || keyStr == 'shop_access') {
        permissionMap['shop'] = val;
      }
      if (keyStr == 'real_time_alerts' || keyStr == 'realTimeAlerts' || keyStr == 'emergency_alerts' || keyStr == 'alerts' || keyStr == 'notifications') {
        permissionMap['real_time_alerts'] = val;
      }
    });

    // Backward compatibility aliases
    permissionMap['camera_snapshot'] = permissionMap['live_video'] == true;
    permissionMap['health_data'] = permissionMap['health'] == true;
    permissionMap['health_reports'] = permissionMap['health'] == true;
    permissionMap['ai_assistant'] = permissionMap['ai_chatbot'] == true;
    permissionMap['custom_music'] = permissionMap['custom_parent_folder'] == true;
    permissionMap['emergency_alerts'] = permissionMap['real_time_alerts'] == true;
    permissionMap['notifications'] = permissionMap['real_time_alerts'] == true;

    debugPrint('[CaregiverPermissionsUpdated] Valid event received for access ${data['caregiverAccessId'] ?? data['permissionId']}. Updated map: $permissionMap');

    // 1. Immediately update Riverpod state for reactive UI updates
    ref.read(caregiverPermissionsProvider.notifier).state = permissionMap;

    // 2. Persist to cache
    final cache = ref.read(cacheServiceProvider);
    final cachedSession = cache.getCaregiverGrantedSession();
    if (cachedSession != null) {
      cache.cacheCaregiverGrantedSession({...cachedSession, 'permissions': permissionMap});
    }

    // 3. Reconcile with authoritative server state
    if (isCaregiverRole) {
      ref.read(authNotifierProvider.notifier).verifyCaregiverActivePermissions(null, true).then((_) {
        debugPrint('[CaregiverPermissionsUpdated] Authoritative reconciliation completed.');
      });
    } else {
      ref.read(caregiverAccessProvider.notifier).loadSessions(loadHistory: true);
    }

    ref.read(musicProvider.notifier).refreshLibrary();
  });

  service.caregiverGrantedStream.listen((data) {
    debugPrint('[CaregiverGranted] Real-time caregiver access granted event received.');
    ref.read(authNotifierProvider.notifier).verifyCaregiverActivePermissions(null, true);
    ref.read(musicProvider.notifier).refreshLibrary();
    try {
      ref.read(caregiverAccessProvider.notifier).loadSessions(loadHistory: true);
    } catch (_) {}
  });

  service.caregiverExtendedStream.listen((data) async {
    debugPrint('[CaregiverExtended] Real-time caregiver access extended event received: $data');

    final session = ref.read(authNotifierProvider).session;
    final isCaregiverRole = session?.role == UserRole.caregiver;

    if (!isCaregiverRole) {
      try {
        ref.read(caregiverAccessProvider.notifier).loadSessions(loadHistory: true);
      } catch (_) {}
      return;
    }

    final rawEventId = data['eventId']?.toString() ??
        data['id']?.toString() ??
        '${data['permissionId'] ?? data['accessId']}_${data['expiresAt'] ?? data['newExpiresAt']}_${data['extensionMinutes'] ?? data['addedMinutes']}';

    if (_processedExtensionEvents.contains(rawEventId)) {
      debugPrint('[CaregiverExtended] Duplicate extension event ignored: $rawEventId');
      return;
    }
    _processedExtensionEvents.add(rawEventId);
    if (_processedExtensionEvents.length > 50) {
      _processedExtensionEvents.remove(_processedExtensionEvents.first);
    }

    final rawNewExpiresAtStr = data['expiresAt'] as String? ??
        data['newExpiresAt'] as String? ??
        data['sessionExpiresAt'] as String?;

    final extMinsNum = data['extensionMinutes'] as num? ??
        data['addedMinutes'] as num? ??
        data['durationMinutes'] as num? ??
        data['addMinutes'] as num? ??
        30;
    final extMins = extMinsNum.toInt();

    final cache = ref.read(cacheServiceProvider);
    final cachedSession = cache.getCaregiverGrantedSession();
    DateTime? currentExpiresAt;
    if (cachedSession != null && cachedSession['expiresAt'] != null) {
      currentExpiresAt = DateTime.tryParse(cachedSession['expiresAt'] as String);
    }

    DateTime newExpiresAt;
    if (rawNewExpiresAtStr != null && DateTime.tryParse(rawNewExpiresAtStr) != null) {
      newExpiresAt = DateTime.tryParse(rawNewExpiresAtStr)!;
    } else if (currentExpiresAt != null) {
      final baseTime = currentExpiresAt.isBefore(DateTime.now()) ? DateTime.now() : currentExpiresAt;
      newExpiresAt = baseTime.add(Duration(minutes: extMins));
    } else {
      newExpiresAt = DateTime.now().add(Duration(minutes: extMins));
    }

    if (cachedSession != null) {
      await cache.cacheCaregiverGrantedSession({
        ...cachedSession,
        'expiresAt': newExpiresAt.toIso8601String(),
      });
    }

    ref.read(caregiverSessionExpiryProvider.notifier).state = newExpiresAt;

    await ref.read(authNotifierProvider.notifier).verifyCaregiverActivePermissions(null, true);

    final extensionText = _formatExtensionText(extMins);
    final remainingDiff = newExpiresAt.difference(DateTime.now());
    final remainingText = _formatRemainingText(remainingDiff);

    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      CaretakerTimeExtendedDialog.show(
        navContext,
        extensionText: extensionText,
        remainingText: remainingText,
      );
    }
  });




  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// WebRTC Service StateNotifierProvider
final webrtcServiceProvider = StateNotifierProvider<WebrtcNotifier, WebrtcState>((ref) {
  final ws = ref.watch(webSocketServiceProvider);
  final notifier = WebrtcNotifier(ws);

  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
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
  final cache = ref.watch(cacheServiceProvider);
  return BabyRepositoryImpl(apiClient: client, cacheService: cache);
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
