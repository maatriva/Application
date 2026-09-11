import 'dart:async';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../domain/repositories/baby_repository.dart';
import '../../../../domain/repositories/device_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../shared/models/baby_profile.dart';
import '../../../../shared/models/client_device_info.dart';
import '../../../../shared/models/profile.dart';
import '../../../../shared/models/vitals_telemetry.dart';
import '../../../../core/services/iot_device_repository.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/storage/cache_service.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final ProfileState? profile;
  final BabyProfile? baby;
  final ClientDeviceInfo? device;
  final Map<String, VitalsTelemetry>? latestTelemetry;

  const DashboardState({
    required this.isLoading,
    this.errorMessage,
    this.profile,
    this.baby,
    this.device,
    this.latestTelemetry,
  });

  factory DashboardState.initial() => const DashboardState(isLoading: true);

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    ProfileState? profile,
    BabyProfile? baby,
    ClientDeviceInfo? device,
    Map<String, VitalsTelemetry>? latestTelemetry,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
      baby: baby ?? this.baby,
      device: device ?? this.device,
      latestTelemetry: latestTelemetry ?? this.latestTelemetry,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        profile,
        baby,
        device,
        latestTelemetry,
      ];
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ProfileRepository _profileRepo;
  final BabyRepository _babyRepo;
  final DeviceRepository _deviceRepo;
  final WebSocketService _wsService;
  final IotDeviceRepository _iotRepo;
  final CacheService _cacheService;
  final ApiClient _apiClient;

  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _deviceStatusSubscription;
  StreamSubscription? _caregiverRevokedSubscription;
  Timer? _heartbeatTimer;
  Timer? _sessionExpiryTimer;
  Timer? _telemetryPollTimer;
  static const Duration _heartbeatTimeout = Duration(seconds: 15);

  DashboardNotifier({
    required ProfileRepository profileRepo,
    required BabyRepository babyRepo,
    required DeviceRepository deviceRepo,
    required WebSocketService wsService,
    required IotDeviceRepository iotRepo,
    required CacheService cacheService,
    required ApiClient apiClient,
  })  : _profileRepo = profileRepo,
        _babyRepo = babyRepo,
        _deviceRepo = deviceRepo,
        _wsService = wsService,
        _iotRepo = iotRepo,
        _cacheService = cacheService,
        _apiClient = apiClient,
        super(DashboardState.initial()) {
    loadDashboard();
    _subscribeToStreams();
    _startSessionExpiryCheck();
    _startTelemetryPolling();
  }

  void _startTelemetryPolling() {
    _telemetryPollTimer?.cancel();
    _telemetryPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted && state.device != null && state.device!.deviceId.isNotEmpty) {
        try {
          final telemetryList = await _deviceRepo.getLatestTelemetry(state.device!.deviceId);
          if (telemetryList.isNotEmpty && mounted) {
            final updatedTelemetry = Map<String, VitalsTelemetry>.from(state.latestTelemetry ?? {});
            for (var v in telemetryList) {
              updatedTelemetry[v.sensorType] = v;
            }
            state = state.copyWith(latestTelemetry: updatedTelemetry);
          }
        } catch (_) {}
      }
    });
  }

  void _resetHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(_heartbeatTimeout, () {
      if (state.device != null && state.device!.status != 'offline') {
        if (kDebugMode) {
          print('[DashboardNotifier] Device heartbeat timeout: marking cradle device as offline');
        }
        final updatedDevice = state.device!.copyWith(status: 'offline');
        state = state.copyWith(device: updatedDevice);
      }
    });
  }

  void _startSessionExpiryCheck() {
    _sessionExpiryTimer?.cancel();
    _sessionExpiryTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final session = _cacheService.getCaregiverGrantedSession();
      if (session != null) {
        final expiresAtStr = session['expiresAt'] as String?;
        if (expiresAtStr != null) {
          final expiresAt = DateTime.tryParse(expiresAtStr);
          if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
            if (kDebugMode) {
              print('[DashboardNotifier] Active caregiver session time expired. Clearing access.');
            }
            await _cacheService.clearCaregiverGrantedSession();
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby');
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_id');
            state = state.copyWith(
              baby: null,
              errorMessage: 'Caregiver access time granted by parent has expired.',
            );
          }
        }
      }
    });
  }

  StreamSubscription? _caregiverGrantedSubscription;
  StreamSubscription? _caregiverPermissionsUpdatedSubscription;
  StreamSubscription? _caregiverExtendedSubscription;

  void _subscribeToStreams() {
    _telemetrySubscription = _iotRepo.telemetryStateStream.listen((telemetryMap) {
      _resetHeartbeatTimer();
      final currentTelemetry = state.latestTelemetry ?? {};
      final updatedTelemetry = Map<String, VitalsTelemetry>.from(currentTelemetry);

      telemetryMap.forEach((sensorType, sensorPayload) {
        updatedTelemetry[sensorType.jsonValue] = VitalsTelemetry(
          sensorType: sensorType.jsonValue,
          value: (sensorPayload.value is num)
              ? (sensorPayload.value as num).toDouble()
              : double.tryParse(sensorPayload.value.toString()) ?? 0.0,
          unit: sensorPayload.unit,
          quality: sensorPayload.quality.jsonValue,
          timestamp: sensorPayload.timestamp,
        );
      });

      state = state.copyWith(latestTelemetry: updatedTelemetry);
    });

    _deviceStatusSubscription = _wsService.deviceStatusStream.listen((statusData) {
      _resetHeartbeatTimer();
      final deviceId = statusData['deviceId'] as String?;
      final status = statusData['status'] as String?;
      
      if (state.device != null && state.device!.deviceId == deviceId) {
        final lastSeenStr = statusData['lastSeen'] as String?;
        final lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : DateTime.now();
        final battery = statusData['battery'] as int?;

        final updatedDevice = state.device!.copyWith(
          status: status?.toLowerCase() ?? 'offline',
          lastSeen: lastSeen,
          battery: battery ?? state.device!.battery,
        );
        state = state.copyWith(device: updatedDevice);
      }
    });

    _caregiverRevokedSubscription = _wsService.caregiverRevokedStream.listen((msg) async {
      if (kDebugMode) {
        print('[DashboardNotifier] Caregiver access revoked by parent: $msg');
      }
      await clearCaregiverStateAndShowScanQR(msg);
    });

    _caregiverGrantedSubscription = _wsService.caregiverGrantedStream.listen((data) async {
      if (kDebugMode) {
        print('[DashboardNotifier] Caregiver access granted event received: $data');
      }
      await loadDashboard(isRefreshing: true);
    });

    _caregiverPermissionsUpdatedSubscription = _wsService.caregiverPermissionsUpdatedStream.listen((data) async {
      if (kDebugMode) {
        print('[DashboardNotifier] Caregiver permissions updated event received: $data');
      }
      await loadDashboard(isRefreshing: true);
    });

    _caregiverExtendedSubscription = _wsService.caregiverExtendedStream.listen((data) async {
      if (kDebugMode) {
        print('[DashboardNotifier] Caregiver access extended event received: $data');
      }
      await loadDashboard(isRefreshing: true);
    });
  }

  Future<void> clearCaregiverStateAndShowScanQR([String? msg]) async {
    if (kDebugMode) {
      print('[DashboardNotifier] Clearing all caregiver state and resetting to Scan QR mode: $msg');
    }
    await _cacheService.clearCaregiverGrantedSession();
    await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby');
    await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_id');
    await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_name');
    _telemetrySubscription?.cancel();
    _wsService.setSelectedBaby('');
    state = DashboardState(
      isLoading: false,
      profile: state.profile,
      baby: null,
      device: null,
      latestTelemetry: null,
      errorMessage: msg,
    );
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _deviceStatusSubscription?.cancel();
    _caregiverRevokedSubscription?.cancel();
    _caregiverGrantedSubscription?.cancel();
    _caregiverPermissionsUpdatedSubscription?.cancel();
    _caregiverExtendedSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _sessionExpiryTimer?.cancel();
    _telemetryPollTimer?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard({bool isRefreshing = false}) async {
    // 0. Auto-resume pending QR code joins
    final prefs = _cacheService.sharedPreferences;
    final pendingJson = prefs.getString('pending_qr_join_data');
    if (pendingJson != null) {
      if (kDebugMode) {
        print('[DashboardNotifier] Found pending QR join data: $pendingJson');
      }
      try {
        final data = jsonDecode(pendingJson);
        final server = data['server'] as String?;
        final token = data['token'] as String?;
        if (token != null) {
          final resolvedServer = ApiConfig.resolveServerUrl(server);
          final candidateServers = <String>{
            resolvedServer,
            ApiConfig.baseUrl,
            if (defaultTargetPlatform == TargetPlatform.android) 'http://10.0.2.2:3000',
            'http://localhost:3000',
            ApiConfig.prodBaseUrl,
            ApiConfig.stagingBaseUrl,
          }.where((s) => s.trim().isNotEmpty).toList();

          print('[DEBUG] Auto-resuming QR join with candidate servers: $candidateServers');
          for (final candidateUrl in candidateServers) {
            try {
              _apiClient.setBaseUrl(candidateUrl);
              await _apiClient.post(
                '/caregivers/accept',
                body: {'token': token},
              );
              print('[DEBUG] Auto-resume invitation ACCEPTED on server: $candidateUrl');
              ApiConfig.setCustomBaseUrl(candidateUrl);
              await prefs.remove('pending_qr_join_data');
              break;
            } catch (e) {
              print('[DEBUG] Auto-resume candidate server $candidateUrl failed: $e');
            }
          }
        }
      } catch (e) {
        print('[DEBUG] Auto-resume join failed: $e');
      }
    }

    if (!isRefreshing) {
      final cachedProfileJson = _cacheService.getCachedUserProfile();
      final cachedDevicesJson = _cacheService.getCachedDevices();
      final cachedBabyJson = _cacheService.getCachedSelectedBaby();

      ProfileState? cachedProfile;
      if (cachedProfileJson != null) {
        cachedProfile = ProfileState.fromJson(cachedProfileJson);
      }

      ClientDeviceInfo? cachedDevice;
      if (cachedDevicesJson.isNotEmpty) {
        cachedDevice = ClientDeviceInfo.fromJson(cachedDevicesJson.first);
      }

      BabyProfile? cachedBaby;
      if (cachedBabyJson != null) {
        cachedBaby = BabyProfile.fromJson(cachedBabyJson);
      }

      Map<String, VitalsTelemetry>? cachedTelemetryMap;
      if (cachedDevice != null) {
        final cachedVitals = _cacheService.getCachedVitals(cachedDevice.deviceId);
        if (cachedVitals != null) {
          cachedTelemetryMap = {
            for (var entry in cachedVitals.entries)
              entry.key: VitalsTelemetry.fromJson(entry.value as Map<String, dynamic>)
          };
        }
      }

      if (cachedProfile != null || cachedBaby != null || cachedDevice != null) {
        state = DashboardState(
          isLoading: false,
          profile: cachedProfile,
          baby: cachedBaby,
          device: cachedDevice,
          latestTelemetry: cachedTelemetryMap,
        );
        if (cachedDevice != null && (cachedDevice.status == 'online' || cachedDevice.status == 'ONLINE' || cachedDevice.status == 'Connected' || cachedDevice.status == 'PAIRED')) {
          _resetHeartbeatTimer();
        }
      } else {
        state = state.copyWith(isLoading: true);
      }
    }

    ProfileState? profile;
    try {
      profile = await _profileRepo.getProfile();
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardNotifier] Profile fetch error: $e');
      }
    }

    BabyProfile? baby;
    String? babyFetchError;
    try {
      final babies = await _babyRepo.getBabies();
      if (babies.isNotEmpty) {
        baby = babies.first;
        _wsService.setSelectedBaby(baby.id);
        await _cacheService.cacheSelectedBaby(baby.toJson());
        await _cacheService.cacheSelectedBabyId(baby.id);
      } else {
        // Check if there is an active Caregiver Granted Session with remaining time
        final caregiverSession = _cacheService.getCaregiverGrantedSession();
        if (caregiverSession != null) {
          final expiresAtStr = caregiverSession['expiresAt'] as String?;
          bool isExpired = false;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.tryParse(expiresAtStr);
            if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
              isExpired = true;
            }
          }

          if (isExpired) {
            if (kDebugMode) {
              print('[DashboardNotifier] Caregiver session has EXPIRED. Clearing access.');
            }
            await _cacheService.clearCaregiverGrantedSession();
            baby = null;
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby');
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_id');
          } else {
            if (kDebugMode) {
              print('[DashboardNotifier] Active caregiver session found with remaining time! Auto-selecting shared baby.');
            }
            final realBabyId = (caregiverSession['babyId'] as String?) ??
                (caregiverSession['baby']?['id'] as String?);
            final babyMap = caregiverSession['baby'] as Map<String, dynamic>? ?? {
              'id': realBabyId ?? 'shared_baby_01',
              'name': caregiverSession['babyName'] ?? 'Shared Baby',
              'dateOfBirth': '2024-01-01',
              'gender': 'female',
            };
            baby = BabyProfile.fromJson(babyMap);
            _wsService.setSelectedBaby(baby.id);
            await _cacheService.cacheSelectedBaby(baby.toJson());
            await _cacheService.cacheSelectedBabyId(baby.id);
          }
        } else {
          // Fallback: Query backend for active caregiver permissions directly
          try {
            final activePermsRes = await _apiClient.get('/caregivers/active-permissions');
            if (activePermsRes != null && activePermsRes['data'] != null && (activePermsRes['data'] as List).isNotEmpty) {
              final activePerm = (activePermsRes['data'] as List).first;
              final realBabyId = (activePerm['babyId'] as String?) ??
                  (activePerm['baby']?['id'] as String?);
              final babyMap = activePerm['baby'] as Map<String, dynamic>? ?? {
                'id': realBabyId ?? 'shared_baby_01',
                'name': activePerm['babyName'] ?? 'Shared Baby',
                'dateOfBirth': '2024-01-01',
                'gender': 'female',
              };
              baby = BabyProfile.fromJson(babyMap);
              _wsService.setSelectedBaby(baby.id);
              await _cacheService.cacheSelectedBaby(baby.toJson());
              await _cacheService.cacheSelectedBabyId(baby.id);

              await _cacheService.cacheCaregiverGrantedSession({
                'babyId': baby.id,
                'expiresAt': activePerm['expiresAt'],
                'permissions': activePerm['permissions'] ?? {'live_monitoring': true},
                'baby': babyMap,
              });
            } else {
              baby = null;
              await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby');
              await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_id');
            }
          } catch (_) {
            baby = null;
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby');
            await _cacheService.sharedPreferences.remove('maatriva_cache_selected_baby_id');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardNotifier] Baby fetch error: $e');
      }
      final cachedMap = _cacheService.getCachedSelectedBaby();
      if (cachedMap != null) {
        baby = BabyProfile.fromJson(cachedMap);
      } else {
        babyFetchError = 'Unable to fetch baby profile from server. Please check your network connection.';
      }
    }

    ClientDeviceInfo? device;
    Map<String, VitalsTelemetry>? telemetryMap;
    try {
      final devices = await _deviceRepo.getDevices();
      device = devices.isNotEmpty ? devices.first : null;

      if (device != null) {
        final telemetryList = await _deviceRepo.getLatestTelemetry(device.deviceId);
        telemetryMap = {for (var v in telemetryList) v.sensorType: v};
        await _cacheService.cacheDevices(devices.map((d) => d.toJson()).toList());
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardNotifier] Devices/telemetry fetch error: $e');
      }
    }

    final finalProfile = profile ?? state.profile;
    final hasCaregiverSession = _cacheService.getCaregiverGrantedSession() != null;
    final finalBaby = (baby == null && !hasCaregiverSession)
        ? null
        : (baby ?? state.baby);
    final finalDevice = finalBaby == null ? null : (device ?? state.device);
    final finalTelemetry = finalBaby == null ? null : (telemetryMap ?? state.latestTelemetry);

    final hasNoDataAtAll = finalProfile == null && finalBaby == null;

    state = DashboardState(
      isLoading: false,
      profile: finalProfile,
      baby: finalBaby,
      device: finalDevice,
      latestTelemetry: finalTelemetry,
      errorMessage: babyFetchError ?? ((hasNoDataAtAll && hasCaregiverSession)
          ? 'Unable to connect to server. Please check your network connection.'
          : null),
    );

    if (finalDevice != null &&
        (finalDevice.status == 'online' ||
            finalDevice.status == 'ONLINE' ||
            finalDevice.status == 'Connected' ||
            finalDevice.status == 'PAIRED')) {
      _resetHeartbeatTimer();
    }
  }

  Future<void> refresh() async {
    await loadDashboard(isRefreshing: true);
  }

  /// Exposes a public method to let future Socket.IO telemetry feeds inject updates in real-time.
  void updateRealTimeTelemetry(String sensorType, double value, {String? unit}) {
    final currentTelemetry = state.latestTelemetry;
    final updatedTelemetry = currentTelemetry != null
        ? Map<String, VitalsTelemetry>.from(currentTelemetry)
        : <String, VitalsTelemetry>{};

    final existing = updatedTelemetry[sensorType];
    updatedTelemetry[sensorType] = VitalsTelemetry(
      sensorType: sensorType,
      value: value,
      unit: unit ?? existing?.unit ?? '',
      quality: 'good',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(latestTelemetry: updatedTelemetry);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final babyRepo = ref.watch(babyRepositoryProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final wsService = ref.watch(webSocketServiceProvider);
  final iotRepo = ref.watch(iotDeviceRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  return DashboardNotifier(
    profileRepo: profileRepo,
    babyRepo: babyRepo,
    deviceRepo: deviceRepo,
    wsService: wsService,
    iotRepo: iotRepo,
    cacheService: cacheService,
    apiClient: apiClient,
  );
});
