import 'package:equatable/equatable.dart';

/// Represents an alert, warning, or emergency event triggered within the MAATRIVA ecosystem.
class AlertPayload extends Equatable {
  /// Unique identifier of the alert instance.
  final String alertId;

  /// Unique identifier of the originating device.
  final String deviceId;

  /// Cradle or room identifier where the alert was generated.
  final String cradleId;

  /// Severity level of the alert ("warning", "danger", "emergency").
  final String severity;

  /// Specific error or warning code (e.g. "high_heart_rate", "gas_detected", "sensor_disconnected").
  final String type;

  /// Plain English description of the event for caregivers.
  final String message;

  /// The parameter value that triggered the alert (e.g. 185.0 BPM).
  final double? value;

  /// The threshold configuration limit that was breached (e.g. 180.0 BPM).
  final double? thresholdLimit;

  /// Point in time when the alert was triggered.
  final DateTime timestamp;

  /// Indicates if a caregiver has viewed/dismissed this alert in the mobile app.
  final bool acknowledged;

  const AlertPayload({
    required this.alertId,
    required this.deviceId,
    required this.cradleId,
    required this.severity,
    required this.type,
    required this.message,
    this.value,
    this.thresholdLimit,
    required this.timestamp,
    this.acknowledged = false,
  });

  /// Factory constructor to instantiate an alert payload from JSON.
  factory AlertPayload.fromJson(Map<String, dynamic> json) {
    return AlertPayload(
      alertId: json['alertId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      cradleId: json['cradleId'] as String? ?? json['roomId'] as String? ?? '',
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

  /// Converts this model instance into a standard JSON dictionary.
  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'deviceId': deviceId,
      'cradleId': cradleId,
      'severity': severity,
      'type': type,
      'message': message,
      if (value != null) 'value': value,
      if (thresholdLimit != null) 'thresholdLimit': thresholdLimit,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  /// Creates a copy of this alert payload with modified parameters.
  AlertPayload copyWith({
    String? alertId,
    String? deviceId,
    String? cradleId,
    String? severity,
    String? type,
    String? message,
    double? value,
    double? thresholdLimit,
    DateTime? timestamp,
    bool? acknowledged,
  }) {
    return AlertPayload(
      alertId: alertId ?? this.alertId,
      deviceId: deviceId ?? this.deviceId,
      cradleId: cradleId ?? this.cradleId,
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
        alertId,
        deviceId,
        cradleId,
        severity,
        type,
        message,
        value,
        thresholdLimit,
        timestamp,
        acknowledged,
      ];
}
