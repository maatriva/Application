import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maatriva/core/iot/errors/iot_errors.dart';
import 'package:maatriva/core/iot/models/enums.dart';
import 'package:maatriva/core/iot/models/sensor_payload.dart';
import 'package:maatriva/core/iot/models/alert_payload.dart';
import 'package:maatriva/core/iot/models/camera_payload.dart';
import 'package:maatriva/core/iot/models/environmental_payload.dart';
import 'package:maatriva/core/iot/models/health_payload.dart';
import 'package:maatriva/core/iot/models/device_info.dart';
import 'package:maatriva/core/iot/services/ble/ble_service.dart';
import 'package:maatriva/core/iot/services/mqtt/mqtt_service.dart';
import 'package:maatriva/core/iot/services/permission_service.dart';
import 'package:maatriva/core/iot/services/device/device_connection_service.dart';
import 'package:maatriva/core/iot/services/device/device_repository.dart';

// Hand-written Mock for BLE Service
class MockBleService implements BleService {
  final scanController = StreamController<List<BleScanResult>>.broadcast();
  final stateController = StreamController<BleConnectionState>.broadcast();
  final charController = StreamController<List<int>>.broadcast();

  bool scanStarted = false;
  bool scanStopped = false;
  bool isConnected = false;
  String? connectedDeviceId;

  @override
  Stream<List<BleScanResult>> startDeviceScan({
    List<String>? withServices,
    Duration timeout = const Duration(seconds: 10),
  }) {
    scanStarted = true;
    return scanController.stream;
  }

  @override
  Future<void> stopDeviceScan() async {
    scanStopped = true;
  }

  @override
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
    bool autoConnect = true,
  }) async {
    isConnected = true;
    connectedDeviceId = deviceId;
    stateController.add(BleConnectionState.connected);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    isConnected = false;
    connectedDeviceId = null;
    stateController.add(BleConnectionState.disconnected);
  }

  @override
  Stream<BleConnectionState> monitorConnectionState(String deviceId) {
    return stateController.stream;
  }

  @override
  Future<void> discoverGattServices(String deviceId) async {}

  @override
  Future<List<int>> readCharacteristic(String deviceId, String serviceUuid, String characteristicUuid) async {
    return [0, 120]; // 120 BPM mock
  }

  @override
  Future<void> writeCharacteristic(String deviceId, String serviceUuid, String characteristicUuid, List<int> value, {bool withoutResponse = false}) async {}

  @override
  Stream<List<int>> subscribeToCharacteristic(String deviceId, String serviceUuid, String characteristicUuid) {
    return charController.stream;
  }

  @override
  Future<int> requestMtu(String deviceId, int mtuSize) async => mtuSize;

  @override
  Future<int> readRssi(String deviceId) async => -60;
}

// Hand-written Mock for MQTT Service
class MockMqttService implements MqttService {
  final _stateController = StreamController<MqttServiceState>.broadcast();
  final _subscriptions = <String, StreamController<MqttMessagePacket>>{};
  
  MqttServiceState _state = MqttServiceState.disconnected;
  int _queueLength = 0;

  @override
  Stream<MqttServiceState> get stateStream => _stateController.stream;

  @override
  MqttServiceState get currentState => _state;

  @override
  int get offlineQueueLength => _queueLength;

  void triggerState(MqttServiceState state) {
    _state = state;
    _stateController.add(state);
  }

  @override
  Future<void> connect({
    required String host,
    required int port,
    required String clientId,
    String? username,
    String? password,
    bool useTls = true,
    String? clientCertificatePem,
    String? privateKeyPem,
    String? lwtTopic,
    String? lwtMessage,
  }) async {
    triggerState(MqttServiceState.connecting);
    triggerState(MqttServiceState.connected);
  }

  @override
  Future<void> disconnect() async {
    triggerState(MqttServiceState.disconnected);
  }

  @override
  Stream<MqttMessagePacket> subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    final controller = StreamController<MqttMessagePacket>.broadcast();
    _subscriptions[topic] = controller;
    return controller.stream;
  }

  @override
  void unsubscribe(String topic) {
    _subscriptions.remove(topic);
  }

  @override
  Future<void> publish(String topic, String payload, {MqttQos qos = MqttQos.atMostOnce, bool retain = false}) async {
    if (_state != MqttServiceState.connected) {
      _queueLength++;
    }
  }

  // Helper to push mock packet to subscribers
  void simulateMessage(String topic, String payload) {
    _subscriptions.forEach((filter, controller) {
      if (filter.endsWith('#') || filter == topic) {
        controller.add(MqttMessagePacket(topic: topic, payload: payload));
      }
    });
  }
}

// Hand-written Mock for Permissions Service
class MockPermissionService implements PermissionService {
  bool permissionsGranted = true;

  @override
  Future<bool> hasAllCorePermissions() async {
    return permissionsGranted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return {};
  }

  @override
  Future<bool> requestBluetooth() async => permissionsGranted;

  @override
  Future<bool> requestLocation() async => permissionsGranted;

  @override
  Future<bool> requestCamera() async => permissionsGranted;

  @override
  Future<bool> requestMicrophone() async => permissionsGranted;

  @override
  Future<bool> requestNotifications() async => permissionsGranted;

  @override
  Future<bool> openAppSettingsScreen() async => true;
}

void main() {
  late MockBleService mockBle;
  late MockMqttService mockMqtt;
  late MockPermissionService mockPermissions;
  late DeviceConnectionService connectionService;
  late DeviceRepository repository;

  setUp(() {
    mockBle = MockBleService();
    mockMqtt = MockMqttService();
    mockPermissions = MockPermissionService();

    connectionService = DeviceConnectionService(
      bleService: mockBle,
      mqttService: mockMqtt,
      permissionService: mockPermissions,
    );

    repository = DeviceRepository(connectionService: connectionService);
  });

  tearDown(() {
    connectionService.dispose();
    repository.dispose();
  });

  group('BLE Scanning & Permission Tests', () {
    test('startDeviceScan fails when permission is missing', () async {
      mockPermissions.permissionsGranted = false;

      await expectLater(
        connectionService.scanForDevices(),
        throwsA(isA<Exception>()),
      );
      expect(connectionService.currentState, DeviceConnectionState.permissionRequired);
    });

    test('startDeviceScan succeeds and starts scanning when permissions are granted', () async {
      final stream = await connectionService.scanForDevices();
      expect(mockBle.scanStarted, true);
      expect(connectionService.currentState, DeviceConnectionState.scanning);

      final results = [
        const BleScanResult(
          deviceId: 'HR-SOCK-02',
          name: 'Smart Sock Wearable',
          rssi: -55,
          serviceUuids: ['180d'],
        )
      ];

      final futureList = stream.first;
      mockBle.scanController.add(results);
      final emitted = await futureList;

      expect(emitted.length, 1);
      expect(emitted[0].deviceId, 'HR-SOCK-02');
    });
  });

  group('Connection State Flow Tests', () {
    test('Successful MQTT and BLE connect sets connection state to connected', () async {
      await connectionService.connectToCradle(
        cradleId: 'CRDL001',
        brokerHost: 'localhost',
        brokerPort: 1883,
        clientId: 'AppClient-01',
        wearableDeviceId: 'HR-SOCK-02',
      );

      expect(connectionService.currentState, DeviceConnectionState.connected);
      expect(mockBle.isConnected, true);
      expect(mockBle.connectedDeviceId, 'HR-SOCK-02');
    });

    test('Losing connection triggers error model and status reconnecting', () async {
      await connectionService.connectToCradle(
        cradleId: 'CRDL001',
        brokerHost: 'localhost',
        brokerPort: 1883,
        clientId: 'AppClient-01',
      );

      await Future.delayed(Duration.zero);
      mockMqtt.triggerState(MqttServiceState.disconnected);
      await Future.delayed(Duration.zero);

      expect(connectionService.currentState, DeviceConnectionState.reconnecting);
    });
  });

  group('Telemetry Parsing & Repository State Mapping Tests', () {
    test('MQTT payload converts correctly and updates Repository states', () async {
      await connectionService.connectToCradle(
        cradleId: 'CRDL001',
        brokerHost: 'localhost',
        brokerPort: 1883,
        clientId: 'AppClient-01',
      );

      // Mock incoming environmental payload under devices/{deviceId}/environment topic
      final mockEnvPayload = {
        'deviceId': 'ESP32-948210',
        'cradleId': 'CRDL001',
        'roomTemperature': 24.5,
        'humidity': 46.2,
        'airQuality': 38,
        'gasLevel': 0.8,
        'heatingPadTemperature': 31.0,
        'quality': 'good',
        'signalStrength': -50,
        'status': 'online',
        'timestamp': '2026-07-21T12:10:30.000Z',
        'sequenceNumber': 500
      };

      final streamFuture = connectionService.environmentalStream.first;
      mockMqtt.simulateMessage(
        'devices/CRDL001/environment',
        jsonEncode(mockEnvPayload),
      );

      final envData = await streamFuture;
      expect(envData.roomTemperature, 24.5);
      expect(envData.heatingPadTemperature, 31.0);
      expect(envData.airQuality, 38);

      expect(repository.currentEnvironmentalPayload?.roomTemperature, 24.5);
    });

    test('BLE vitals stream parsed to SensorPayload and cached in Repository', () async {
      await connectionService.connectToCradle(
        cradleId: 'CRDL001',
        brokerHost: 'localhost',
        brokerPort: 1883,
        clientId: 'AppClient-01',
        wearableDeviceId: 'HR-SOCK-02',
      );

      final telemetryFuture = connectionService.telemetryStream.first;
      
      mockBle.charController.add([0, 122]);

      final parsed = await telemetryFuture;
      expect(parsed.type, SensorType.heartRate);
      expect(parsed.value, 122);
      expect(parsed.unit, 'bpm');

      expect(repository.latestTelemetry[SensorType.heartRate]?.value, 122);
      expect(repository.getTelemetryHistory(SensorType.heartRate).length, 1);
    });
  });
}
