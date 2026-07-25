import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/repositories/device_repository.dart';
import '../../shared/models/client_device_info.dart';
import '../../shared/models/vitals_telemetry.dart';

/// Concrete implementation of [DeviceRepository] with SharedPreferences caching support.
class DeviceRepositoryImpl implements DeviceRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  const DeviceRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<void> pairDevice({
    required String deviceId,
    required String deviceName,
    required String type,
    String firmwareVersion = '1.0.0',
    String protocol = 'Wi-Fi',
    required String babyId,
  }) async {
    try {
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
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<List<ClientDeviceInfo>> getDevices() async {
    try {
      final res = await _apiClient.get('/devices') as List;
      final devices = res
          .map((json) => ClientDeviceInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      await _cacheService.cacheDevices(devices.map((d) => d.toJson()).toList());
      return devices;
    } catch (e) {
      if (e is ApiException && e.statusCode != 0) {
        rethrow;
      }
      // Fallback to cached devices offline
      final cached = _cacheService.getCachedDevices();
      if (cached.isNotEmpty) {
        return cached.map((json) => ClientDeviceInfo.fromJson(json)).toList();
      }
      if (e is ApiException) {
        rethrow;
      }
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<List<VitalsTelemetry>> getLatestTelemetry(String deviceId) async {
    try {
      final res = await _apiClient.get('/devices/$deviceId/latest') as List;
      final vitals = res
          .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
          .toList();

      final vitalsMap = {for (var v in vitals) v.sensorType: v.toJson()};
      await _cacheService.cacheVitals(deviceId, vitalsMap);
      return vitals;
    } catch (e) {
      if (e is ApiException && e.statusCode != 0) {
        rethrow;
      }
      // Fallback to cached telemetry offline
      final cached = _cacheService.getCachedVitals(deviceId);
      if (cached != null) {
        return cached.values
            .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      if (e is ApiException) {
        rethrow;
      }
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<List<VitalsTelemetry>> getTelemetryHistory(
    String deviceId, {
    required String sensorType,
    int limit = 50,
  }) async {
    try {
      final res = await _apiClient.get(
        '/devices/$deviceId/history?type=$sensorType&limit=$limit',
      ) as List;
      return res
          .map((json) => VitalsTelemetry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<void> renameDevice(String deviceId, String newName) async {
    try {
      await _apiClient.patch(
        '/devices/$deviceId/rename',
        body: {'deviceName': newName},
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<void> reassignBaby(String deviceId, String babyId) async {
    try {
      await _apiClient.patch(
        '/devices/$deviceId/reassign',
        body: {'babyId': babyId},
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<void> unpairDevice(String deviceId) async {
    try {
      await _apiClient.delete('/devices/$deviceId/unpair');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }
}
