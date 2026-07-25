import '../../shared/models/alarm_alert.dart';

/// Contract definition for evaluating and managing smart cradle alerts.
abstract class AlertRepository {
  Future<List<AlarmAlert>> getActiveAlerts(String cradleId);

  Future<void> acknowledgeAlert(String alertId);

  // New alerts CRUD operations
  Future<List<AlarmAlert>> getAlerts();

  Future<void> markAsRead(String alertId);

  Future<void> deleteAlert(String alertId);

  Future<void> clearAllAlerts();
}
