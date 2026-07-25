import '../../../shared/models/health_report.dart';

abstract class AiRepository {
  /// Fetches a health report/insights for a specific baby.
  /// [type] can be 'daily', 'weekly', or 'monthly'.
  Future<HealthReport?> getHealthReport(String babyId, String type);
}
