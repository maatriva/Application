import 'package:equatable/equatable.dart';

/// Strongly-typed notification model representation.
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String category; // 'critical', 'health', 'sleep', 'activity', 'caregiver', 'reports'
  final String priority; // 'high', 'medium', 'low'
  final String deviceResponsible;
  final String sensorResponsible;
  final String detailedExplanation;
  final String recommendedAction;
  final String aiInsight;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    required this.category,
    required this.priority,
    required this.deviceResponsible,
    required this.sensorResponsible,
    required this.detailedExplanation,
    required this.recommendedAction,
    required this.aiInsight,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      category: json['category'] as String? ?? 'health',
      priority: json['priority'] as String? ?? 'medium',
      deviceResponsible: json['deviceResponsible'] as String? ?? '',
      sensorResponsible: json['sensorResponsible'] as String? ?? '',
      detailedExplanation: json['detailedExplanation'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
      aiInsight: json['aiInsight'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'category': category,
      'priority': priority,
      'deviceResponsible': deviceResponsible,
      'sensorResponsible': sensorResponsible,
      'detailedExplanation': detailedExplanation,
      'recommendedAction': recommendedAction,
      'aiInsight': aiInsight,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? category,
    String? priority,
    String? deviceResponsible,
    String? sensorResponsible,
    String? detailedExplanation,
    String? recommendedAction,
    String? aiInsight,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      deviceResponsible: deviceResponsible ?? this.deviceResponsible,
      sensorResponsible: sensorResponsible ?? this.sensorResponsible,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      aiInsight: aiInsight ?? this.aiInsight,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        timestamp,
        isRead,
        category,
        priority,
        deviceResponsible,
        sensorResponsible,
        detailedExplanation,
        recommendedAction,
        aiInsight,
      ];
}
