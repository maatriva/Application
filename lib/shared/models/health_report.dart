import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AlertSeverity { warning, critical, resolved }

class HealthMetric extends Equatable {
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

  const HealthMetric({
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

  HealthMetric copyWith({
    String? label,
    String? value,
    String? unit,
    IconData? icon,
    String? changeText,
    Color? iconBgColor,
    Color? iconColor,
    String? badgeText,
    Color? badgeColor,
    IconData? trendIcon,
    Color? trendColor,
  }) {
    return HealthMetric(
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      changeText: changeText ?? this.changeText,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      iconColor: iconColor ?? this.iconColor,
      badgeText: badgeText ?? this.badgeText,
      badgeColor: badgeColor ?? this.badgeColor,
      trendIcon: trendIcon ?? this.trendIcon,
      trendColor: trendColor ?? this.trendColor,
    );
  }

  @override
  List<Object?> get props => [
        label,
        value,
        unit,
        icon,
        changeText,
        iconBgColor,
        iconColor,
        badgeText,
        badgeColor,
        trendIcon,
        trendColor,
      ];
}

class HealthInsight extends Equatable {
  final String text;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const HealthInsight({
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  HealthInsight copyWith({
    String? text,
    IconData? icon,
    Color? iconColor,
    Color? bgColor,
  }) {
    return HealthInsight(
      text: text ?? this.text,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  @override
  List<Object?> get props => [text, icon, iconColor, bgColor];
}

class HealthAlert extends Equatable {
  final String title;
  final String timeText;
  final AlertSeverity severity;
  final IconData icon;
  final Color color;

  const HealthAlert({
    required this.title,
    required this.timeText,
    required this.severity,
    required this.icon,
    required this.color,
  });

  HealthAlert copyWith({
    String? title,
    String? timeText,
    AlertSeverity? severity,
    IconData? icon,
    Color? color,
  }) {
    return HealthAlert(
      title: title ?? this.title,
      timeText: timeText ?? this.timeText,
      severity: severity ?? this.severity,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [title, timeText, severity, icon, color];
}

class TimelineEvent extends Equatable {
  final String time;
  final String activity;

  const TimelineEvent({required this.time, required this.activity});

  TimelineEvent copyWith({String? time, String? activity}) {
    return TimelineEvent(
      time: time ?? this.time,
      activity: activity ?? this.activity,
    );
  }

  @override
  List<Object?> get props => [time, activity];
}

class ReportHistoryItem extends Equatable {
  final int score;
  final String date;
  final String summary;

  const ReportHistoryItem({
    required this.score,
    required this.date,
    required this.summary,
  });

  factory ReportHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReportHistoryItem(
      score: json['score'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'date': date,
      'summary': summary,
    };
  }

  ReportHistoryItem copyWith({
    int? score,
    String? date,
    String? summary,
  }) {
    return ReportHistoryItem(
      score: score ?? this.score,
      date: date ?? this.date,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [score, date, summary];
}

class HealthReport extends Equatable {
  final int score;
  final String status; // E.g., 'Excellent'
  final String aiSummary;
  final List<HealthMetric> metrics;
  final List<HealthInsight> insights;
  final List<HealthAlert> alerts;
  final List<TimelineEvent> timeline;
  final List<ReportHistoryItem> history;

  const HealthReport({
    required this.score,
    required this.status,
    required this.aiSummary,
    required this.metrics,
    required this.insights,
    required this.alerts,
    required this.timeline,
    required this.history,
  });

  HealthReport copyWith({
    int? score,
    String? status,
    String? aiSummary,
    List<HealthMetric>? metrics,
    List<HealthInsight>? insights,
    List<HealthAlert>? alerts,
    List<TimelineEvent>? timeline,
    List<ReportHistoryItem>? history,
  }) {
    return HealthReport(
      score: score ?? this.score,
      status: status ?? this.status,
      aiSummary: aiSummary ?? this.aiSummary,
      metrics: metrics ?? this.metrics,
      insights: insights ?? this.insights,
      alerts: alerts ?? this.alerts,
      timeline: timeline ?? this.timeline,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [score, status, aiSummary, metrics, insights, alerts, timeline, history];
}
