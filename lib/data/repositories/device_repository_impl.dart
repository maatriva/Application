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
  Future<ClientDeviceInfo> registerDevice({
    required String deviceId,
    required String deviceName,
    required String type,
    String? registrationKey,
    String? firmwareVersion,
    String? protocol,
  }) async {
    try {
      final res = await _apiClient.post(
        '/devices/register',
        body: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'type': type,
          if (registrationKey != null) 'registrationKey': registrationKey,
          if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
          if (protocol != null) 'protocol': protocol,
        },
      );
      return ClientDeviceInfo.fromJson(res as Map<String, dynamic>);
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
  Future<ClientDeviceInfo> pairDevice({
    required String registrationKey,
    required String babyId,
  }) async {
    try {
      final res = await _apiClient.post(
        '/devices/pair',
        body: {
          'registrationKey': registrationKey,
          'babyId': babyId,
        },
      );
      return ClientDeviceInfo.fromJson(res as Map<String, dynamic>);
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
      final res = await _apiClient.get('/devices');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] is List) {
        rawList = res['data'] as List;
      }
      final devices = rawList
          .whereType<Map>()
          .map((json) => ClientDeviceInfo.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      await _cacheService.cacheDevices(devices.map((d) => d.toJson()).toList());
      return devices;
    } catch (e) {
      if (e is ApiException && e.statusCode != 0) {
        rethrow;
      }
      final cached = _cacheService.getCachedDevices();
      if (cached.isNotEmpty) {
        return cached.map((json) => ClientDeviceInfo.fromJson(json)).toList();
      }
      return [];
    }
  }

  @override
  Future<List<VitalsTelemetry>> getLatestTelemetry(String deviceId) async {
    try {
      final res = await _apiClient.get('/devices/$deviceId/latest');
      List<VitalsTelemetry> vitals = [];
      Map<String, dynamic>? dataMap;

      if (res is List) {
        vitals = res
            .whereType<Map>()
            .map((json) => VitalsTelemetry.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else if (res is Map<String, dynamic>) {
        if (res['data'] is List) {
          vitals = (res['data'] as List)
              .whereType<Map>()
              .map((json) => VitalsTelemetry.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        } else if (res['data'] is Map<String, dynamic>) {
          dataMap = res['data'] as Map<String, dynamic>;
        } else {
          dataMap = res;
        }
      }

      if (dataMap != null) {
        final timestampStr = dataMap['timestamp'] as String? ?? DateTime.now().toIso8601String();
        final timestamp = DateTime.tryParse(timestampStr) ?? DateTime.now();

        void addVital(String sensorType, dynamic value, String unit) {
          if (value != null && value is num) {
            vitals.add(VitalsTelemetry(
              sensorType: sensorType,
              value: value.toDouble(),
              unit: unit,
              quality: 'good',
              timestamp: timestamp,
            ));
          }
        }

        addVital('heart_rate', dataMap['heartRate'] ?? dataMap['heart_rate'], 'bpm');
        addVital('breathing_rate', dataMap['breathingRate'] ?? dataMap['respirationRate'] ?? dataMap['breathing_rate'] ?? dataMap['respiration_rate'], 'rpm');
        addVital('body_temperature', dataMap['bodyTemperature'] ?? dataMap['body_temperature'], '°C');
        addVital('room_temperature', dataMap['roomTemperature'] ?? dataMap['room_temperature'], '°C');
        addVital('humidity', dataMap['humidity'], '%');
        addVital('air_quality', dataMap['airQuality'] ?? dataMap['air_quality'], 'AQI');

        if (dataMap['cryDetected'] != null || dataMap['cry_detected'] != null) {
          final cry = (dataMap['cryDetected'] ?? dataMap['cry_detected']) == true;
          vitals.add(VitalsTelemetry(
            sensorType: 'cry_detection',
            value: cry ? 1.0 : 0.0,
            unit: '',
            quality: 'good',
            timestamp: timestamp,
          ));
        }

        if (dataMap['movementDetected'] != null || dataMap['movement_detected'] != null) {
          final move = (dataMap['movementDetected'] ?? dataMap['movement_detected']) == true;
          vitals.add(VitalsTelemetry(
            sensorType: 'movement_detection',
            value: move ? 1.0 : 0.0,
            unit: '',
            quality: 'good',
            timestamp: timestamp,
          ));
        }
      }

      if (vitals.isNotEmpty) {
        final vitalsMap = {for (var v in vitals) v.sensorType: v.toJson()};
        await _cacheService.cacheVitals(deviceId, vitalsMap);
      }
      return vitals;
    } catch (e) {
      final cached = _cacheService.getCachedVitals(deviceId);
      if (cached != null) {
        return cached.values
            .whereType<Map>()
            .map((json) => VitalsTelemetry.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
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
