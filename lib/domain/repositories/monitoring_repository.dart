import '../../shared/enums/sensor_enums.dart';
import '../../shared/models/sensor_payload.dart';
import '../../shared/models/alert_payload.dart';
import '../../core/services/iot_device_repository.dart';

/// Contract definition for real-time WebSocket telemetry updates.
abstract class MonitoringRepository {
  Stream<Map<SensorType, SensorPayload>> get telemetryStream;

  Stream<List<AlertPayload>> get activeAlertsStream;

  Stream<DeviceConnectionState> get connectionStream;
}
