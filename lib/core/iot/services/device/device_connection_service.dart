import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../../errors/iot_errors.dart';
import '../../models/enums.dart';
import '../../models/sensor_payload.dart';
import '../../models/alert_payload.dart';
import '../../models/camera_payload.dart';
import '../../models/environmental_payload.dart';
import '../../models/health_payload.dart';
import '../../models/device_info.dart';
import '../ble/ble_service.dart';
import '../mqtt/mqtt_service.dart';
import '../permission_service.dart';

/// Unified connection state of the IoT ecosystem.
enum DeviceConnectionState {
  unsupported,
  permissionRequired,
  disconnected,
  scanning,
  connecting,
  connected,
  syncing,
  reconnecting,
  error
}

/// Service managing device aggregation, stream decoding, and connection status.
class DeviceConnectionService {
  final BleService _bleService;
  final MqttService _mqttService;
  final PermissionService _permissionService;

  // Stream Controllers for unified outputs
  final StreamController<SensorPayload> _telemetryController =
      StreamController<SensorPayload>.broadcast();
  final StreamController<AlertPayload> _alertController =
      StreamController<AlertPayload>.broadcast();
  final StreamController<CameraPayload> _cameraController =
      StreamController<CameraPayload>.broadcast();
  final StreamController<EnvironmentalPayload> _environmentalController =
      StreamController<EnvironmentalPayload>.broadcast();
  final StreamController<HealthPayload> _healthController =
      StreamController<HealthPayload>.broadcast();
  final StreamController<DeviceConnectionState> _stateController =
      StreamController<DeviceConnectionState>.broadcast();
  final StreamController<IotError> _errorController =
      StreamController<IotError>.broadcast();

  DeviceConnectionState _currentState = DeviceConnectionState.disconnected;
  StreamSubscription? _bleStateSub;
  StreamSubscription? _mqttStateSub;
  final List<StreamSubscription> _dataSubscriptions = [];

  DeviceConnectionService({
    required BleService bleService,
    required MqttService mqttService,
    required PermissionService permissionService,
  })  : _bleService = bleService,
        _mqttService = mqttService,
        _permissionService = permissionService {
    _setupStateListeners();
  }

  // Stream Getters
  Stream<SensorPayload> get telemetryStream => _telemetryController.stream;
  Stream<AlertPayload> get alertStream => _alertController.stream;
  Stream<CameraPayload> get cameraStream => _cameraController.stream;
  Stream<EnvironmentalPayload> get environmentalStream => _environmentalController.stream;
  Stream<HealthPayload> get healthStream => _healthController.stream;
  Stream<DeviceConnectionState> get connectionStateStream => _stateController.stream;
  Stream<IotError> get errorStream => _errorController.stream;

  DeviceConnectionState get currentState => _currentState;

  void _updateState(DeviceConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void _setupStateListeners() {
    _mqttStateSub = _mqttService.stateStream.listen((state) {
      switch (state) {
        case MqttServiceState.connected:
          _updateState(DeviceConnectionState.connected);
          break;
        case MqttServiceState.connecting:
          _updateState(DeviceConnectionState.connecting);
          break;
        case MqttServiceState.disconnected:
          if (_currentState == DeviceConnectionState.connected) {
            _updateState(DeviceConnectionState.reconnecting);
          } else {
            _updateState(DeviceConnectionState.disconnected);
          }
          break;
        case MqttServiceState.error:
          _updateState(DeviceConnectionState.error);
          _errorController.add(const IotError(
            code: IotErrorCode.brokerUnavailable,
            severity: IotErrorSeverity.critical,
            message: 'MQTT Server disconnected due to an internal broker error.',
            recoverySteps: [
              'Check home internet connectivity.',
              'Verify the cloud server status.',
            ],
          ));
          break;
      }
    });
  }

  /// Checks permissions and scans for BLE wearables or Hubs.
  Future<Stream<List<BleScanResult>>> scanForDevices({List<String>? serviceUuids}) async {
    final permissionsOk = await _permissionService.hasAllCorePermissions();
    if (!permissionsOk) {
      _updateState(DeviceConnectionState.permissionRequired);
      _errorController.add(IotError.permissionDenied('Bluetooth & Location'));
      throw Exception('Missing required permissions for device scanning.');
    }

    _updateState(DeviceConnectionState.scanning);
    return _bleService.startDeviceScan(withServices: serviceUuids);
  }

  /// Stops scanning for devices.
  Future<void> stopScan() async {
    await _bleService.stopDeviceScan();
    if (_currentState == DeviceConnectionState.scanning) {
      _updateState(DeviceConnectionState.disconnected);
    }
  }

  /// Main connect method. Uses per-device client certificate parameters if supplied.
  Future<void> connectToCradle({
    required String cradleId,
    required String brokerHost,
    required int brokerPort,
    required String clientId,
    String? username,
    String? password,
    String? clientCertificatePem, // Per-device certificate
    String? privateKeyPem,         // Per-device private key
    String? wearableDeviceId,
  }) async {
    _updateState(DeviceConnectionState.connecting);

    try {
      // Connect to MQTT Broker using per-device credentials
      await _mqttService.connect(
        host: brokerHost,
        port: brokerPort,
        clientId: clientId,
        username: username,
        password: password,
        clientCertificatePem: clientCertificatePem,
        privateKeyPem: privateKeyPem,
        lwtTopic: 'devices/$cradleId/status',
        lwtMessage: jsonEncode({
          'deviceId': clientId,
          'status': 'offline',
          'timestamp': DateTime.now().toIso8601String()
        }),
      );

      // Subscribe to MQTT topics under devices/{deviceId}/ telemetry patterns
      _subscribeToMqttTopics(cradleId);

      // Connect to BLE wearable if identifier is supplied
      if (wearableDeviceId != null) {
        await _connectBleWearable(wearableDeviceId);
      }
    } catch (e) {
      _updateState(DeviceConnectionState.error);
      _errorController.add(IotError(
        code: IotErrorCode.connectionTimeout,
        severity: IotErrorSeverity.critical,
        message: 'Failed to establish cradle network sync.',
        recoverySteps: const [
          'Verify Cradle Hub is powered on and within range.',
          'Ensure correct MQTT server details.',
        ],
        technicalDetails: e.toString(),
      ));
      rethrow;
    }
  }

  /// Disconnects all active BLE and MQTT streams.
  Future<void> disconnectAll() async {
    for (final sub in _dataSubscriptions) {
      await sub.cancel();
    }
    _dataSubscriptions.clear();

    await _mqttService.disconnect();
    _bleStateSub?.cancel();
    _bleStateSub = null;

    _updateState(DeviceConnectionState.disconnected);
  }

  // Subscribe to MQTT topics matching devices/{deviceId}/telemetry
  void _subscribeToMqttTopics(String deviceId) {
    // 1. Raw Telemetry under devices/{deviceId}/telemetry
    final telemetryStream =
        _mqttService.subscribe('devices/$deviceId/telemetry');
    final telSub = telemetryStream.listen((packet) {
      try {
        final decoded = jsonDecode(packet.payload) as Map<String, dynamic>;
        final payload = SensorPayload.fromJson(decoded);
        _telemetryController.add(payload);
      } catch (e) {
        _errorController.add(IotError(
          code: IotErrorCode.invalidPacket,
          severity: IotErrorSeverity.info,
          message: 'Malformed telemetry packet parsed.',
          recoverySteps: const ['Firmware updates may be required.'],
          technicalDetails: e.toString(),
        ));
      }
    });
    _dataSubscriptions.add(telSub);

    // 2. Alert Broadcasts (evaluated and sent by backend)
    final alertStream = _mqttService.subscribe('devices/$deviceId/alerts');
    final alertSub = alertStream.listen((packet) {
      try {
        final decoded = jsonDecode(packet.payload) as Map<String, dynamic>;
        final payload = AlertPayload.fromJson(decoded);
        _alertController.add(payload);
      } catch (e) {
        // Log parse failure
      }
    });
    _dataSubscriptions.add(alertSub);

    // 3. Camera status
    final cameraStream = _mqttService.subscribe('devices/$deviceId/camera');
    final camSub = cameraStream.listen((packet) {
      try {
        final decoded = jsonDecode(packet.payload) as Map<String, dynamic>;
        final payload = CameraPayload.fromJson(decoded);
        _cameraController.add(payload);
      } catch (e) {
        // Log parse failure
      }
    });
    _dataSubscriptions.add(camSub);

    // 4. Cluster Payloads (Health & Environment)
    final envStream = _mqttService.subscribe('devices/$deviceId/environment');
    final envSub = envStream.listen((packet) {
      try {
        final decoded = jsonDecode(packet.payload) as Map<String, dynamic>;
        final payload = EnvironmentalPayload.fromJson(decoded);
        _environmentalController.add(payload);
      } catch (e) {
        // Log parse failure
      }
    });
    _dataSubscriptions.add(envSub);

    final healthStream = _mqttService.subscribe('devices/$deviceId/health');
    final healthSub = healthStream.listen((packet) {
      try {
        final decoded = jsonDecode(packet.payload) as Map<String, dynamic>;
        final payload = HealthPayload.fromJson(decoded);
        _healthController.add(payload);
      } catch (e) {
        // Log parse failure
      }
    });
    _dataSubscriptions.add(healthSub);
  }

  // Connect BLE peripheral and setup characteristic subscribers
  Future<void> _connectBleWearable(String deviceId) async {
    _bleStateSub?.cancel();
    
    // Monitor connection state
    _bleStateSub = _bleService.monitorConnectionState(deviceId).listen((state) {
      if (state == BleConnectionState.disconnected &&
          _currentState == DeviceConnectionState.connected) {
        _errorController.add(IotError.lostConnection(deviceId));
      }
    });

    await _bleService.connect(deviceId, autoConnect: true);
    await _bleService.discoverGattServices(deviceId);

    // Subscribe to vitals characteristic updates (e.g. Heart Rate standard uuid '180d' / char '2a37')
    final hrStream =
        _bleService.subscribeToCharacteristic(deviceId, '180d', '2a37');
    final hrSub = hrStream.listen((bytes) {
      _parseBleVitals(deviceId, bytes);
    }, onError: (err) {
      _errorController.add(IotError(
        code: IotErrorCode.subscriptionFailure,
        severity: IotErrorSeverity.warning,
        message: 'Wearable sensors subscription failed.',
        recoverySteps: const ['Restart Bluetooth on phone.', 'Ensure sock has charge.'],
        technicalDetails: err.toString(),
      ));
    });
    _dataSubscriptions.add(hrSub);
  }

  // Decodes characteristic byte array into standard SensorPayload structures
  void _parseBleVitals(String deviceId, List<int> bytes) {
    if (bytes.length < 2) return;

    final int heartRate = bytes[1];

    final payload = SensorPayload(
      deviceId: deviceId,
      sensorId: 'BLE-PPG',
      type: SensorType.heartRate,
      value: heartRate,
      unit: 'bpm',
      timestamp: DateTime.now(),
      quality: SensorQuality.good,
      battery: null,
      signalStrength: -55,
      status: SensorStatus.online,
      firmwareVersion: '1.0.0',
      cradleId: 'LOCAL_BLE',
      sequenceNumber: 0,
    );

    _telemetryController.add(payload);
  }

  /// Sends control command over MQTT.
  Future<void> sendCommand(String deviceId, String action, String value) async {
    final topic = 'devices/$deviceId/commands';
    final payload = jsonEncode({
      'action': action,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _mqttService.publish(topic, payload, qos: MqttQos.atLeastOnce);
  }

  /// Releases resources.
  void dispose() {
    _bleStateSub?.cancel();
    _mqttStateSub?.cancel();
    for (final sub in _dataSubscriptions) {
      sub.cancel();
    }
    _telemetryController.close();
    _alertController.close();
    _cameraController.close();
    _environmentalController.close();
    _healthController.close();
    _stateController.close();
    _errorController.close();
  }
}
