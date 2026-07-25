import 'dart:async';
import '../../core/services/iot_device_repository.dart';
import '../../core/services/websocket_service.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../shared/enums/sensor_enums.dart';
import '../../shared/models/sensor_payload.dart';
import '../../shared/models/alert_payload.dart';

/// Concrete implementation of [MonitoringRepository] bridging WebSocket streams.
class MonitoringRepositoryImpl implements MonitoringRepository {
  final IotDeviceRepository _iotDeviceRepository;
  final WebSocketService _webSocketService;

  const MonitoringRepositoryImpl({
    required IotDeviceRepository iotDeviceRepository,
    required WebSocketService webSocketService,
  })  : _iotDeviceRepository = iotDeviceRepository,
        _webSocketService = webSocketService;

  @override
  Stream<Map<SensorType, SensorPayload>> get telemetryStream =>
      _iotDeviceRepository.telemetryStateStream;

  @override
  Stream<DeviceConnectionState> get connectionStream =>
      _iotDeviceRepository.connectionStateStream;

  @override
  Stream<List<AlertPayload>> get activeAlertsStream {
    return _webSocketService.alertStream.map((_) => _iotDeviceRepository.activeAlerts);
  }
}
