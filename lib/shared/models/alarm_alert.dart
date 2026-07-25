import 'package:equatable/equatable.dart';

/// Represents an Alert evaluated on the backend.
class AlarmAlert extends Equatable {
  final String id;
  final String severity;
  final String type;
  final String message;
  final double? value;
  final double? thresholdLimit;
  final DateTime timestamp;
  final bool acknowledged;

  const AlarmAlert({
    required this.id,
    required this.severity,
    required this.type,
    required this.message,
    this.value,
    this.thresholdLimit,
    required this.timestamp,
    required this.acknowledged,
  });

  factory AlarmAlert.fromJson(Map<String, dynamic> json) {
    return AlarmAlert(
      id: json['id'] as String? ?? json['alertId'] as String? ?? '',
      severity: json['severity'] as String? ?? 'warning',
      type: json['type'] as String? ?? 'general_alert',
      message: json['message'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble(),
      thresholdLimit: (json['thresholdLimit'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity,
      'type': type,
      'message': message,
      if (value != null) 'value': value,
      if (thresholdLimit != null) 'thresholdLimit': thresholdLimit,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  AlarmAlert copyWith({
    String? id,
    String? severity,
    String? type,
    String? message,
    double? value,
    double? thresholdLimit,
    DateTime? timestamp,
    bool? acknowledged,
  }) {
    return AlarmAlert(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      message: message ?? this.message,
      value: value ?? this.value,
      thresholdLimit: thresholdLimit ?? this.thresholdLimit,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  @override
  List<Object?> get props => [
        id,
        severity,
        type,
        message,
        value,
        thresholdLimit,
        timestamp,
        acknowledged,
      ];
}
