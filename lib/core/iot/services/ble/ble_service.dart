import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Representation of a scanned Bluetooth device.
class BleScanResult {
  final String deviceId;
  final String name;
  final int rssi;
  final List<String> serviceUuids;

  const BleScanResult({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.serviceUuids,
  });
}

/// Enums for BLE device connection state.
enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting
}

/// Interface defining the BLE service contract.
abstract class BleService {
  /// Scans for nearby BLE peripherals. Filters by service UUIDs if provided.
  Stream<List<BleScanResult>> startDeviceScan({
    List<String>? withServices,
    Duration timeout = const Duration(seconds: 10),
  });

  /// Stops an active BLE scan.
  Future<void> stopDeviceScan();

  /// Connects to a specific BLE device.
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
    bool autoConnect = true,
  });

  /// Disconnects from a BLE device.
  Future<void> disconnect(String deviceId);

  /// Monitors connection state of a specific device.
  Stream<BleConnectionState> monitorConnectionState(String deviceId);

  /// Discovers GATT services for a connected device.
  Future<void> discoverGattServices(String deviceId);

  /// Reads a characteristic value.
  Future<List<int>> readCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  );

  /// Writes to a characteristic.
  Future<void> writeCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    List<int> value, {
    bool withoutResponse = false,
  });

  /// Subscribes to value changes of a characteristic.
  Stream<List<int>> subscribeToCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  );

  /// Requests a larger Maximum Transmission Unit (MTU) size.
  Future<int> requestMtu(String deviceId, int mtuSize);

  /// Reads the current signal strength (RSSI).
  Future<int> readRssi(String deviceId);
}

/// Production implementation of BLE Service utilizing `flutter_blue_plus`.
class FlutterBluePlusBleService implements BleService {
  final Map<String, BluetoothDevice> _connectedDevices = {};

  FlutterBluePlusBleService();

  @override
  Stream<List<BleScanResult>> startDeviceScan({
    List<String>? withServices,
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (FlutterBluePlus.isScanningNow) {
      FlutterBluePlus.stopScan();
    }

    final serviceFilters = withServices != null
        ? withServices.map((uuid) => Guid(uuid)).toList()
        : <Guid>[];

    FlutterBluePlus.startScan(
      withServices: serviceFilters,
      timeout: timeout,
    );

    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return BleScanResult(
          deviceId: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty
              ? r.device.platformName
              : (r.advertisementData.advName.isNotEmpty
                  ? r.advertisementData.advName
                  : 'Unknown Device'),
          rssi: r.rssi,
          serviceUuids:
              r.advertisementData.serviceUuids.map((g) => g.toString()).toList(),
        );
      }).toList();
    });
  }

  @override
  Future<void> stopDeviceScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
    bool autoConnect = true,
  }) async {
    final device = BluetoothDevice.fromId(deviceId);
    _connectedDevices[deviceId] = device;

    await device.connect(
      autoConnect: autoConnect,
      timeout: timeout,
    );
  }

  @override
  Future<void> disconnect(String deviceId) async {
    final device = _connectedDevices[deviceId];
    if (device != null) {
      await device.disconnect();
      _connectedDevices.remove(deviceId);
    }
  }

  @override
  Stream<BleConnectionState> monitorConnectionState(String deviceId) {
    final device = _connectedDevices[deviceId] ?? BluetoothDevice.fromId(deviceId);
    _connectedDevices[deviceId] = device;

    return device.connectionState.map((state) {
      switch (state) {
        case BluetoothConnectionState.disconnected:
          return BleConnectionState.disconnected;
        case BluetoothConnectionState.connecting:
          return BleConnectionState.connecting;
        case BluetoothConnectionState.connected:
          return BleConnectionState.connected;
        case BluetoothConnectionState.disconnecting:
          return BleConnectionState.disconnecting;
      }
    });
  }

  @override
  Future<void> discoverGattServices(String deviceId) async {
    final device = _getConnectedDevice(deviceId);
    await device.discoverServices();
  }

  @override
  Future<List<int>> readCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final char = await _getCharacteristic(deviceId, serviceUuid, characteristicUuid);
    return await char.read();
  }

  @override
  Future<void> writeCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    List<int> value, {
    bool withoutResponse = false,
  }) async {
    final char = await _getCharacteristic(deviceId, serviceUuid, characteristicUuid);
    await char.write(value, allowLongWrite: !withoutResponse, withoutResponse: withoutResponse);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) {
    final controller = StreamController<List<int>>();

    _getCharacteristic(deviceId, serviceUuid, characteristicUuid).then((char) async {
      await char.setNotifyValue(true);
      final sub = char.lastValueStream.listen(
        (val) => controller.add(val),
        onError: (err) => controller.addError(err),
      );
      controller.onCancel = () {
        char.setNotifyValue(false);
        sub.cancel();
      };
    }).catchError((err) {
      controller.addError(err);
    });

    return controller.stream;
  }

  @override
  Future<int> requestMtu(String deviceId, int mtuSize) async {
    final device = _getConnectedDevice(deviceId);
    return await device.requestMtu(mtuSize);
  }

  @override
  Future<int> readRssi(String deviceId) async {
    final device = _getConnectedDevice(deviceId);
    return await device.readRssi();
  }

  // Helper resolvers
  BluetoothDevice _getConnectedDevice(String deviceId) {
    final device = _connectedDevices[deviceId];
    if (device == null) {
      throw Exception('Device $deviceId is not connected or registered in the service.');
    }
    return device;
  }

  Future<BluetoothCharacteristic> _getCharacteristic(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final device = _getConnectedDevice(deviceId);
    final services = await device.discoverServices();
    
    final service = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
      orElse: () => throw Exception('Service $serviceUuid not found on device $deviceId'),
    );

    final char = service.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
      orElse: () => throw Exception('Characteristic $characteristicUuid not found in service $serviceUuid'),
    );

    return char;
  }
}
