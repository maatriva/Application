import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../shared/enums/sensor_enums.dart';
import '../../shared/models/sensor_payload.dart';
import '../../shared/models/alert_payload.dart';
import '../../shared/models/camera_payload.dart';
import '../../shared/models/environmental_payload.dart';
import '../../shared/models/health_payload.dart';
import '../../shared/models/device_info.dart';
import 'websocket_service.dart';

/// Connection states for the IoT repository client interface.
enum DeviceConnectionState { disconnected, connecting, connected, error }

/// Repository that coordinates the parsing, state storage, and history caching of IoT telemetry.
/// Decoupled from direct hardware communication, it consumes telemetry streams from the cloud WebSocket service.
class IotDeviceRepository {
  final WebSocketService _webSocketService;

  // Active state stores
  final Map<SensorType, SensorPayload> _latestTelemetry = {};
  final List<DeviceInfo> _registeredDevices = [];
  final List<AlertPayload> _activeAlerts = [];
  CameraPayload? _currentCameraPayload;
  EnvironmentalPayload? _currentEnvironmentalPayload;
  HealthPayload? _currentHealthPayload;

  // History logs for rendering analytics charts (capped at 100 entries per metric)
  final Map<SensorType, List<SensorPayload>> _historyCache = {};
  static const int maxCacheSize = 100;

  // Streams for repositories listeners
  final StreamController<Map<SensorType, SensorPayload>>
  _telemetryUpdateController =
      StreamController<Map<SensorType, SensorPayload>>.broadcast();
  final StreamController<List<DeviceInfo>> _deviceRegistryController =
      StreamController<List<DeviceInfo>>.broadcast();

  final List<StreamSubscription> _subscriptions = [];

  IotDeviceRepository({required WebSocketService webSocketService})
    : _webSocketService = webSocketService {
    _startRepositoryListeners();
  }

  // Getters
  Map<SensorType, SensorPayload> get latestTelemetry =>
      Map.unmodifiable(_latestTelemetry);
  List<DeviceInfo> get registeredDevices =>
      List.unmodifiable(_registeredDevices);
  List<AlertPayload> get activeAlerts => List.unmodifiable(_activeAlerts);
  CameraPayload? get currentCameraPayload => _currentCameraPayload;
  EnvironmentalPayload? get currentEnvironmentalPayload =>
      _currentEnvironmentalPayload;
  HealthPayload? get currentHealthPayload => _currentHealthPayload;

  Stream<Map<SensorType, SensorPayload>> get telemetryStateStream =>
      _telemetryUpdateController.stream;
  Stream<List<DeviceInfo>> get deviceRegistryStream =>
      _deviceRegistryController.stream;

  Stream<DeviceConnectionState> get connectionStateStream =>
      _webSocketService.stateStream.map((state) {
        switch (state) {
          case WsConnectionState.connected:
            return DeviceConnectionState.connected;
          case WsConnectionState.connecting:
          case WsConnectionState.reconnecting:
            return DeviceConnectionState.connecting;
          case WsConnectionState.error:
            return DeviceConnectionState.error;
          case WsConnectionState.disconnected:
          case WsConnectionState.disconnecting:
          default:
            return DeviceConnectionState.disconnected;
        }
      });

  bool _validateSensorPayload(SensorPayload payload) {
    if (payload.value == null) {
      if (kDebugMode) {
        print('[IotDeviceRepository] Validation Error: Null value for ${payload.type.jsonValue}');
      }
      return false;
    }

    final val = payload.value;
    switch (payload.type) {
      case SensorType.heartRate:
        final bpm = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (bpm == null || bpm < 40.0 || bpm > 220.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Heart Rate ($bpm bpm)');
          }
          return false;
        }
        break;
      case SensorType.breathingRate:
        final rpm = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (rpm == null || rpm < 10.0 || rpm > 100.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Breathing Rate ($rpm rpm)');
          }
          return false;
        }
        break;
      case SensorType.bodyTemperature:
        final temp = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (temp == null || temp < 30.0 || temp > 45.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Body Temp ($temp °C)');
          }
          return false;
        }
        break;
      case SensorType.roomTemperature:
        final temp = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (temp == null || temp < 10.0 || temp > 50.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Room Temp ($temp °C)');
          }
          return false;
        }
        break;
      case SensorType.humidity:
        final hum = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (hum == null || hum < 0.0 || hum > 100.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Humidity ($hum %)');
          }
          return false;
        }
        break;
      case SensorType.airQuality:
        final aqi = (val is num) ? val.toDouble() : double.tryParse(val.toString());
        if (aqi == null || aqi < 0.0 || aqi > 500.0) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Invalid Air Quality ($aqi AQI)');
          }
          return false;
        }
        break;
      case SensorType.unknown:
        if (kDebugMode) {
          print('[IotDeviceRepository] Validation Error: Unknown sensor type');
        }
        return false;
      default:
        break;
    }

    final existing = _latestTelemetry[payload.type];
    if (existing != null) {
      if (payload.timestamp.isBefore(existing.timestamp) ||
          payload.timestamp.isAtSameMomentAs(existing.timestamp)) {
        if (kDebugMode) {
          print('[IotDeviceRepository] Validation Error: Duplicate/out-of-order timestamp for ${payload.type.jsonValue}');
        }
        return false;
      }
    }

    return true;
  }

  void _startRepositoryListeners() {
    // 1. Raw Telemetry Event listener
    final telSub = _webSocketService.telemetryStream.listen((payload) {
      // Decode sensor payload if a sensor type is present
      final typeStr = payload['type'] as String?;
      if (typeStr != null) {
        try {
          final sensorPayload = SensorPayload.fromJson(payload);
          if (_validateSensorPayload(sensorPayload)) {
            _latestTelemetry[sensorPayload.type] = sensorPayload;

            // Update history buffer
            final history = _historyCache[sensorPayload.type] ?? [];
            history.add(sensorPayload);
            if (history.length > maxCacheSize) {
              history.removeAt(0);
            }
            _historyCache[sensorPayload.type] = history;

            _telemetryUpdateController.add(_latestTelemetry);
          }
        } catch (e) {
          if (kDebugMode) {
            print('[IotDeviceRepository] Validation Error: Corrupted telemetry payload ($e)');
          }
        }
      }

      // Check and decode health telemetry
      if (payload.containsKey('heartRate') ||
          payload.containsKey('breathingRate')) {
        try {
          _currentHealthPayload = HealthPayload.fromJson(payload);
        } catch (_) {}
      }

      // Check and decode environmental telemetry
      if (payload.containsKey('roomTemperature') ||
          payload.containsKey('humidity')) {
        try {
          _currentEnvironmentalPayload = EnvironmentalPayload.fromJson(payload);
        } catch (_) {}
      }

      // Check and decode camera stream configuration
      if (payload.containsKey('rtspUrl') || payload.containsKey('webrtcUrl')) {
        try {
          _currentCameraPayload = CameraPayload.fromJson(payload);
        } catch (_) {}
      }
    });
    _subscriptions.add(telSub);

    // 2. Alert warnings listener
    final alertSub = _webSocketService.alertStream.listen((alertData) {
      try {
        final alertMap = alertData is Map && alertData.containsKey('alert')
            ? alertData['alert'] as Map<String, dynamic>
            : alertData as Map<String, dynamic>;
        final alert = AlertPayload.fromJson(alertMap);
        _activeAlerts.removeWhere((a) => a.alertId == alert.alertId);
        if (!alert.acknowledged) {
          _activeAlerts.add(alert);
        }
      } catch (_) {}
    });
    _subscriptions.add(alertSub);
  }

  /// Retrieve cache logs for telemetry charts.
  List<SensorPayload> getTelemetryHistory(SensorType type) {
    return List.unmodifiable(_historyCache[type] ?? []);
  }

  /// Registers or pairs a new peripheral config via Cloud.
  void registerDevice(DeviceInfo device) {
    _registeredDevices.removeWhere((d) => d.deviceId == device.deviceId);
    _registeredDevices.add(device);
    _deviceRegistryController.add(_registeredDevices);
  }

  /// Removes a peripheral configuration via Cloud.
  void unregisterDevice(String deviceId) {
    _registeredDevices.removeWhere((d) => d.deviceId == deviceId);
    _deviceRegistryController.add(_registeredDevices);
  }

  /// Manually clears active alerts.
  void clearAlert(String alertId) {
    _activeAlerts.removeWhere((a) => a.alertId == alertId);
  }

  /// Cleanup listeners.
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _telemetryUpdateController.close();
    _deviceRegistryController.close();
  }
}
