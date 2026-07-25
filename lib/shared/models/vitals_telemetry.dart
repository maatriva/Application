import 'package:equatable/equatable.dart';

/// Represents latest metrics telemetry read.
class VitalsTelemetry extends Equatable {
  final String sensorType;
  final double value;
  final String unit;
  final String quality;
  final DateTime timestamp;

  const VitalsTelemetry({
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.quality,
    required this.timestamp,
  });

  factory VitalsTelemetry.fromJson(Map<String, dynamic> json) {
    return VitalsTelemetry(
      sensorType:
          json['sensorType'] as String? ?? json['type'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      quality: json['quality'] as String? ?? 'good',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensorType': sensorType,
      'value': value,
      'unit': unit,
      'quality': quality,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  VitalsTelemetry copyWith({
    String? sensorType,
    double? value,
    String? unit,
    String? quality,
    DateTime? timestamp,
  }) {
    return VitalsTelemetry(
      sensorType: sensorType ?? this.sensorType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      quality: quality ?? this.quality,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [sensorType, value, unit, quality, timestamp];
}
