class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String
  category; // 'critical', 'health', 'sleep', 'activity', 'caregiver', 'reports'
  final String priority; // 'high', 'medium', 'low'
  final String deviceResponsible;
  final String sensorResponsible;
  final String detailedExplanation;
  final String recommendedAction;
  final String aiInsight;

  NotificationModel({
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
}
