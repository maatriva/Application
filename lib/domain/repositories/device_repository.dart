import '../../shared/models/client_device_info.dart';
import '../../shared/models/vitals_telemetry.dart';

/// Contract definition for managing paired cradle devices and retrieving telemetry logs.
abstract class DeviceRepository {
  Future<ClientDeviceInfo> registerDevice({
    required String deviceId,
    required String deviceName,
    required String type,
    String? registrationKey,
    String? firmwareVersion,
    String? protocol,
  });

  Future<ClientDeviceInfo> pairDevice({
    required String registrationKey,
    required String babyId,
  });

  Future<List<ClientDeviceInfo>> getDevices();

  Future<List<VitalsTelemetry>> getLatestTelemetry(String deviceId);

  Future<List<VitalsTelemetry>> getTelemetryHistory(
    String deviceId, {
    required String sensorType,
    int limit = 50,
  });

  Future<void> renameDevice(String deviceId, String newName);

  Future<void> reassignBaby(String deviceId, String babyId);

  Future<void> unpairDevice(String deviceId);
}
