import '../models/models.dart';
import '../network/api_client.dart';

class AlertRepository {
  final ApiClient _apiClient;

  const AlertRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Retrieves list of warnings for device.
  Future<List<AlarmAlert>> getAlerts(String deviceId, {bool acknowledged = false}) async {
    final res = await _apiClient.get('/devices/$deviceId/alerts?acknowledged=$acknowledged') as List;
    return res.map((json) => AlarmAlert.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Acknowledges an active warning.
  Future<AlarmAlert> acknowledgeAlert(String alertId) async {
    final res = await _apiClient.patch('/alerts/$alertId/acknowledge');
    return AlarmAlert.fromJson(res as Map<String, dynamic>);
  }
}
