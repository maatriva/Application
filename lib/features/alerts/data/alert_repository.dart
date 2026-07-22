import '../../../shared/models/alarm_alert.dart';
import '../../../core/services/api_client.dart';

class AlertRepository {
  final ApiClient _apiClient;

  const AlertRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// Retrieves un-acknowledged alert list for active cradle.
  Future<List<AlarmAlert>> getActiveAlerts(String cradleId) async {
    final res =
        await _apiClient.get('/alerts/active?cradleId=$cradleId') as List;
    return res
        .map((json) => AlarmAlert.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Caregiver marks an alert acknowledged to silence alarm.
  Future<void> acknowledgeAlert(String alertId) async {
    await _apiClient.post('/alerts/$alertId/acknowledge');
  }
}
