import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/services/providers.dart';
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

  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _deviceStatusSubscription;
  Timer? _heartbeatTimer;
  static const Duration _heartbeatTimeout = Duration(seconds: 15);

  DashboardNotifier({
    required ProfileRepository profileRepo,
    required BabyRepository babyRepo,
    required DeviceRepository deviceRepo,
    required WebSocketService wsService,
    required IotDeviceRepository iotRepo,
    required CacheService cacheService,
  })  : _profileRepo = profileRepo,
        _babyRepo = babyRepo,
        _deviceRepo = deviceRepo,
        _wsService = wsService,
        _iotRepo = iotRepo,
        _cacheService = cacheService,
        super(DashboardState.initial()) {
    loadDashboard();
    _subscribeToStreams();
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
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _deviceStatusSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard({bool isRefreshing = false}) async {
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
        if (cachedDevice != null && (cachedDevice.status == 'online' || cachedDevice.status == 'Connected')) {
          _resetHeartbeatTimer();
        }
      } else {
        state = state.copyWith(isLoading: true);
      }
    }

    try {
      // 1. Fetch parent user profile details
      final profile = await _profileRepo.getProfile();

      // 2. Fetch parent's babies
      final babies = await _babyRepo.getBabies();
      final baby = babies.isNotEmpty ? babies.first : null;

      if (baby != null) {
        _wsService.setSelectedBaby(baby.id);
        await _cacheService.cacheSelectedBaby(baby.toJson());
      }

      // 3. Fetch paired devices
      final devices = await _deviceRepo.getDevices();
      final device = devices.isNotEmpty ? devices.first : null;

      // 4. Fetch telemetry if a device exists
      Map<String, VitalsTelemetry>? telemetryMap;
      if (device != null) {
        final telemetryList = await _deviceRepo.getLatestTelemetry(device.deviceId);
        telemetryMap = {for (var v in telemetryList) v.sensorType: v};
        
        await _cacheService.cacheDevices(devices.map((d) => d.toJson()).toList());
      }

      state = DashboardState(
        isLoading: false,
        profile: profile,
        baby: baby,
        device: device,
        latestTelemetry: telemetryMap,
      );

      if (device != null && (device.status == 'online' || device.status == 'Connected')) {
        _resetHeartbeatTimer();
      }
    } on ApiException catch (e) {
      if (state.profile == null && state.baby == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        );
      }
    } catch (_) {
      if (state.profile == null && state.baby == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No internet connection or server unreachable.',
        );
      }
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

  return DashboardNotifier(
    profileRepo: profileRepo,
    babyRepo: babyRepo,
    deviceRepo: deviceRepo,
    wsService: wsService,
    iotRepo: iotRepo,
    cacheService: cacheService,
  );
});
