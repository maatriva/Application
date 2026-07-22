import '../../../shared/models/client_device_info.dart';
import '../../../shared/models/vitals_telemetry.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/cache_service.dart';

class DeviceRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  const DeviceRepository({
    required ApiClient apiClient,
    required CacheService cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService;

  /// Pairs device to baby.
  Future<void> pairDevice({
    required String deviceId,
    required String deviceName,
    required String type,
    String firmwareVersion = '1.0.0',
    String protocol = 'Wi-Fi',
    required String babyId,
  }) async {
    await _apiClient.post(
      '/devices/pair',
      body: {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'type': type,
        'firmwareVersion': firmwareVersion,
        'protocol': protocol,
        'babyId': babyId,
      },
    );
  }

  /// Lists devices with local offline fallback.
  Future<List<ClientDeviceInfo>> getDevices() async {
    try {
      final res = await _apiClient.get('/devices') as List;
      final devices = res
          .map(
            (json) => ClientDeviceInfo.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // Update cache
      await _cacheService.cacheDevices(devices.map((d) => d.toJson()).toList());
      return devices;
    } catch (_) {
      // Offline fallback
      final cached = _cacheService.getCachedDevices();
      return cached.map((json) => ClientDeviceInfo.fromJson(json)).toList();
    }
  }

  /// Gets latest vitals map with offline caching support.
  Future<List<VitalsTelemetry>> getLatestTelemetry(String deviceId) async {
    try {
      final res = await _apiClient.get('/devices/$deviceId/latest') as List;
      final vitals = res
          .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache latest state
      final vitalsMap = {for (var v in vitals) v.sensorType: v.toJson()};
      await _cacheService.cacheVitals(deviceId, vitalsMap);
      return vitals;
    } catch (_) {
      // Offline fallback
      final cached = _cacheService.getCachedVitals(deviceId);
      if (cached == null) return [];
      return cached.values
          .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  /// Retrieves partitioned history list for charting.
  Future<List<VitalsTelemetry>> getTelemetryHistory(
    String deviceId, {
    required String sensorType,
    int limit = 50,
  }) async {
    final res =
        await _apiClient.get(
              '/devices/$deviceId/history?type=$sensorType&limit=$limit',
            )
            as List;
    return res
        .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
