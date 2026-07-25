import '../../core/network/api_client.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../shared/models/alarm_alert.dart';

/// Concrete implementation of [AlertRepository] managing cradle safety alerts.
class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _apiClient;

  const AlertRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<AlarmAlert>> getActiveAlerts(String cradleId) async {
    // Retain old method for backward compatibility
    try {
      final res = await getAlerts();
      return res.where((a) => !a.acknowledged).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    // Retain old method for backward compatibility
    await markAsRead(alertId);
  }

  @override
  Future<List<AlarmAlert>> getAlerts() async {
    try {
      final res = await _apiClient.get('/alerts', requireAuth: true);
      final responseMap = res as Map<String, dynamic>;
      final listData = responseMap['data'] as List;
      return listData
          .map((json) => AlarmAlert.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Unable to load alerts. Please check your internet connection.',
      );
    }
  }

  @override
  Future<void> markAsRead(String alertId) async {
    try {
      await _apiClient.patch('/alerts/$alertId/read', requireAuth: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Failed to update alert state. Please try again.',
      );
    }
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    try {
      await _apiClient.delete('/alerts/$alertId', requireAuth: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Failed to delete alert. Please try again.',
      );
    }
  }

  @override
  Future<void> clearAllAlerts() async {
    try {
      await _apiClient.delete('/alerts', requireAuth: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Failed to clear alerts. Please try again.',
      );
    }
  }
}
