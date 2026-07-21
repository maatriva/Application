import 'dart:async';
import '../../models/enums.dart';
import '../../models/sensor_payload.dart';
import '../../models/alert_payload.dart';
import '../../models/camera_payload.dart';
import '../../models/environmental_payload.dart';
import '../../models/health_payload.dart';
import '../../models/device_info.dart';
import 'device_connection_service.dart';

/// Repository that coordinates the parsing, state storage, and history caching of IoT telemetry.
class DeviceRepository {
  final DeviceConnectionService _connectionService;

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
  final StreamController<Map<SensorType, SensorPayload>> _telemetryUpdateController =
      StreamController<Map<SensorType, SensorPayload>>.broadcast();
  final StreamController<List<DeviceInfo>> _deviceRegistryController =
      StreamController<List<DeviceInfo>>.broadcast();

  final List<StreamSubscription> _subscriptions = [];

  DeviceRepository({required DeviceConnectionService connectionService})
      : _connectionService = connectionService {
    _startRepositoryListeners();
  }

  // Getters
  Map<SensorType, SensorPayload> get latestTelemetry => Map.unmodifiable(_latestTelemetry);
  List<DeviceInfo> get registeredDevices => List.unmodifiable(_registeredDevices);
  List<AlertPayload> get activeAlerts => List.unmodifiable(_activeAlerts);
  CameraPayload? get currentCameraPayload => _currentCameraPayload;
  EnvironmentalPayload? get currentEnvironmentalPayload => _currentEnvironmentalPayload;
  HealthPayload? get currentHealthPayload => _currentHealthPayload;

  Stream<Map<SensorType, SensorPayload>> get telemetryStateStream =>
      _telemetryUpdateController.stream;
  Stream<List<DeviceInfo>> get deviceRegistryStream =>
      _deviceRegistryController.stream;
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionService.connectionStateStream;

  void _startRepositoryListeners() {
    // 1. Raw Vitals and Sensor Feeds
    final telSub = _connectionService.telemetryStream.listen((payload) {
      _latestTelemetry[payload.type] = payload;
      
      // Update history buffer
      final history = _historyCache[payload.type] ?? [];
      history.add(payload);
      if (history.length > maxCacheSize) {
        history.removeAt(0);
      }
      _historyCache[payload.type] = history;

      _telemetryUpdateController.add(_latestTelemetry);
    });
    _subscriptions.add(telSub);

    // 2. Alert warnings
    final alertSub = _connectionService.alertStream.listen((alert) {
      _activeAlerts.removeWhere((a) => a.alertId == alert.alertId);
      if (!alert.acknowledged) {
        _activeAlerts.add(alert);
      }
    });
    _subscriptions.add(alertSub);

    // 3. Camera details
    final camSub = _connectionService.cameraStream.listen((cam) {
      _currentCameraPayload = cam;
    });
    _subscriptions.add(camSub);

    // 4. Cluster payloads
    final envSub = _connectionService.environmentalStream.listen((env) {
      _currentEnvironmentalPayload = env;
    });
    _subscriptions.add(envSub);

    final healthSub = _connectionService.healthStream.listen((health) {
      _currentHealthPayload = health;
    });
    _subscriptions.add(healthSub);
  }

  /// Retreive cache logs for telemetry charts.
  List<SensorPayload> getTelemetryHistory(SensorType type) {
    return List.unmodifiable(_historyCache[type] ?? []);
  }

  /// Registers or pairs a new peripheral.
  void registerDevice(DeviceInfo device) {
    _registeredDevices.removeWhere((d) => d.deviceId == device.deviceId);
    _registeredDevices.add(device);
    _deviceRegistryController.add(_registeredDevices);
  }

  /// Removes a peripheral from the paired device configuration list.
  void unregisterDevice(String deviceId) {
    _registeredDevices.removeWhere((d) => d.deviceId == deviceId);
    _deviceRegistryController.add(_registeredDevices);
  }

  /// Manually clears acknowledged alarms.
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
