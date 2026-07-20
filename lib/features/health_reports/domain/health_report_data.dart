import 'package:flutter/material.dart';

enum AlertSeverity { warning, critical, resolved }

class HealthMetric {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String changeText; // E.g., 'L: 36.2  H: 36.8'
  final Color iconBgColor;
  final Color iconColor;
  final String? badgeText; // E.g., '92% QUALITY', 'SAFE'
  final Color? badgeColor;
  final IconData? trendIcon;
  final Color? trendColor;

  HealthMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.changeText,
    required this.iconBgColor,
    required this.iconColor,
    this.badgeText,
    this.badgeColor,
    this.trendIcon,
    this.trendColor,
  });
}

class HealthInsight {
  final String text;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  HealthInsight({
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class HealthAlert {
  final String title;
  final String timeText;
  final AlertSeverity severity;
  final IconData icon;
  final Color color;

  HealthAlert({
    required this.title,
    required this.timeText,
    required this.severity,
    required this.icon,
    required this.color,
  });
}

class TimelineEvent {
  final String time;
  final String activity;

  TimelineEvent({required this.time, required this.activity});
}

class ReportHistoryItem {
  final int score;
  final String date;
  final String summary;

  ReportHistoryItem({
    required this.score,
    required this.date,
    required this.summary,
  });
}

class HealthReport {
  final int score;
  final String status; // E.g., 'Excellent'
  final String aiSummary;
  final List<HealthMetric> metrics;
  final List<HealthInsight> insights;
  final List<HealthAlert> alerts;
  final List<TimelineEvent> timeline;
  final List<ReportHistoryItem> history;

  HealthReport({
    required this.score,
    required this.status,
    required this.aiSummary,
    required this.metrics,
    required this.insights,
    required this.alerts,
    required this.timeline,
    required this.history,
  });
}
