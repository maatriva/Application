import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../shared/models/health_report.dart';

class AiRepositoryImpl implements AiRepository {
  final ApiClient _apiClient;

  const AiRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<HealthReport?> getHealthReport(String babyId, String type) async {
    try {
      final res = await _apiClient.get(
        '/ai/reports/$babyId',
        queryParameters: {'type': type},
      );

      final responseMap = res as Map<String, dynamic>;

      // Check if backend returned insufficient data status
      if (responseMap.containsKey('insufficientData') && responseMap['insufficientData'] == true) {
        return null;
      }

      final score = responseMap['score'] as int? ?? 90;
      final status = responseMap['status'] as String? ?? 'Excellent';
      final aiSummary = responseMap['aiSummary'] as String? ?? '';

      // Parse Metrics
      final metricsList = responseMap['metrics'] as List? ?? [];
      final List<HealthMetric> metrics = metricsList.map((m) {
        final map = m as Map<String, dynamic>;
        final label = map['label'] as String? ?? '';
        final value = map['value'] as String? ?? '';
        final unit = map['unit'] as String? ?? '';
        final changeText = map['changeText'] as String? ?? '';
        final trendStr = map['trend'] as String?;

        return HealthMetric(
          label: label,
          value: value,
          unit: unit,
          icon: _getMetricIcon(label),
          changeText: changeText,
          iconBgColor: _getMetricBgColor(label),
          iconColor: _getMetricColor(label),
          badgeText: map['badgeText'] as String?,
          badgeColor: map['badgeText'] != null ? _getMetricBadgeColor(label, map['badgeText'] as String) : null,
          trendIcon: _getTrendIcon(trendStr),
          trendColor: _getTrendColor(trendStr, label),
        );
      }).toList();

      // Parse Insights
      final insightsList = responseMap['insights'] as List? ?? [];
      final List<HealthInsight> insights = insightsList.map((i) {
        final map = i as Map<String, dynamic>;
        final text = map['text'] as String? ?? '';
        final typeStr = map['type'] as String? ?? 'success';

        return HealthInsight(
          text: text,
          icon: _getInsightIcon(typeStr),
          iconColor: _getInsightColor(typeStr),
          bgColor: _getInsightBgColor(typeStr),
        );
      }).toList();

      // Parse Alerts
      final alertsList = responseMap['alerts'] as List? ?? [];
      final List<HealthAlert> alerts = alertsList.map((a) {
        final map = a as Map<String, dynamic>;
        final title = map['title'] as String? ?? '';
        final timeText = map['timeText'] as String? ?? '';
        final severityStr = map['severity'] as String? ?? 'critical';

        final isResolved = severityStr == 'resolved';
        return HealthAlert(
          title: title,
          timeText: timeText,
          severity: isResolved ? AlertSeverity.resolved : AlertSeverity.critical,
          icon: title.contains('Temp') ? Icons.thermostat_rounded : Icons.warning_amber_rounded,
          color: isResolved ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
        );
      }).toList();

      // Parse Timeline
      final timelineList = responseMap['timeline'] as List? ?? [];
      final List<TimelineEvent> timeline = timelineList.map((t) {
        final map = t as Map<String, dynamic>;
        return TimelineEvent(
          time: map['time'] as String? ?? '',
          activity: map['activity'] as String? ?? '',
        );
      }).toList();

      // Parse History
      final historyList = responseMap['history'] as List? ?? [];
      final List<ReportHistoryItem> history = historyList.map((h) {
        return ReportHistoryItem.fromJson(h as Map<String, dynamic>);
      }).toList();

      return HealthReport(
        score: score,
        status: status,
        aiSummary: aiSummary,
        metrics: metrics,
        insights: insights,
        alerts: alerts,
        timeline: timeline,
        history: history,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Could not deserialize AI insights report: ${e.toString()}',
      );
    }
  }

  // Helper mapping functions
  IconData _getMetricIcon(String label) {
    switch (label.toLowerCase()) {
      case 'body temp':
        return Icons.thermostat_outlined;
      case 'heart rate':
        return Icons.favorite_border_rounded;
      case 'room temp':
        return Icons.home_outlined;
      case 'sleep duration':
        return Icons.nights_stay_outlined;
      case 'motion activity':
        return Icons.waves_rounded;
      case 'baby position':
        return Icons.airline_seat_flat_rounded;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  Color _getMetricColor(String label) {
    switch (label.toLowerCase()) {
      case 'body temp':
        return const Color(0xFFFF9800); // Amber
      case 'heart rate':
        return const Color(0xFF8855EC); // Purple
      case 'room temp':
        return const Color(0xFF2196F3); // Blue
      case 'sleep duration':
        return const Color(0xFF673AB7); // Dark Purple
      case 'motion activity':
        return const Color(0xFF4CAF50); // Green
      case 'baby position':
        return const Color(0xFF8855EC); // Purple
      default:
        return Colors.blue;
    }
  }

  Color _getMetricBgColor(String label) {
    switch (label.toLowerCase()) {
      case 'body temp':
        return const Color(0xFFFFF3CD);
      case 'heart rate':
        return const Color(0xFFF3EDFA);
      case 'room temp':
        return const Color(0xFFE3F2FD);
      case 'sleep duration':
        return const Color(0xFFEDE7F6);
      case 'motion activity':
        return const Color(0xFFE8F5E9);
      case 'baby position':
        return const Color(0xFFF3EDFA);
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getMetricBadgeColor(String label, String badgeText) {
    if (badgeText.contains('QUALITY') || badgeText == 'SAFE' || badgeText == 'EXCELLENT') {
      return const Color(0xFFE8F5E9); // Green background
    }
    return const Color(0xFFFFEBEE); // Red background
  }

  IconData? _getTrendIcon(String? trend) {
    if (trend == 'up') return Icons.trending_up_rounded;
    if (trend == 'down') return Icons.trending_down_rounded;
    if (trend == 'flat') return Icons.trending_flat_rounded;
    return null;
  }

  Color? _getTrendColor(String? trend, String label) {
    if (trend == 'up') {
      if (label.toLowerCase() == 'room temp' || label.toLowerCase() == 'body temp') {
        return const Color(0xFFFF5722); // Orange/Red warning
      }
      return const Color(0xFF8855EC);
    }
    if (trend == 'down' || trend == 'flat') {
      return const Color(0xFF4CAF50); // Safe green
    }
    return null;
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF8855EC);
      case 'warning':
        return const Color(0xFFE53935);
      case 'info':
      default:
        return const Color(0xFF2196F3);
    }
  }

  Color _getInsightBgColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFFF6F2FD);
      case 'warning':
        return const Color(0xFFFFEBEE);
      case 'info':
      default:
        return const Color(0xFFE3F2FD);
    }
  }
}
