import 'package:equatable/equatable.dart';

/// Represents a unified telemetry history row retrieved from TimescaleDB.
class TelemetryRecord extends Equatable {
  final String id;
  final String deviceId;
  final String? babyId;
  final DateTime timestamp;
  final double? heartRate;
  final double? breathingRate;
  final double? bodyTemperature;
  final double? roomTemperature;
  final double? humidity;
  final bool? movementDetected;
  final bool? cryDetected;
  final String? sleepStage;
  final double? airQuality;
  final int? batteryLevel;

  const TelemetryRecord({
    required this.id,
    required this.deviceId,
    this.babyId,
    required this.timestamp,
    this.heartRate,
    this.breathingRate,
    this.bodyTemperature,
    this.roomTemperature,
    this.humidity,
    this.movementDetected,
    this.cryDetected,
    this.sleepStage,
    this.airQuality,
    this.batteryLevel,
  });

  /// Factory constructor to instantiate a telemetry record from a JSON map.
  factory TelemetryRecord.fromJson(Map<String, dynamic> json) {
    return TelemetryRecord(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? json['device_id'] as String? ?? '',
      babyId: json['babyId'] as String? ?? json['baby_id'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      heartRate: (json['heartRate'] ?? json['heart_rate'] as num?)?.toDouble(),
      breathingRate: (json['respirationRate'] ?? json['respiration_rate'] as num?)?.toDouble() ??
          (json['breathingRate'] ?? json['breathing_rate'] as num?)?.toDouble(),
      bodyTemperature: (json['bodyTemperature'] ?? json['body_temperature'] as num?)?.toDouble(),
      roomTemperature: (json['roomTemperature'] ?? json['room_temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      movementDetected: json['movementDetected'] as bool? ?? json['movement_detected'] as bool?,
      cryDetected: json['cryDetected'] as bool? ?? json['cry_detected'] as bool?,
      sleepStage: json['sleepStage'] as String? ?? json['sleep_stage'] as String?,
      airQuality: (json['airQuality'] ?? json['air_quality'] as num?)?.toDouble(),
      batteryLevel: json['batteryLevel'] as int? ?? json['battery_level'] as int?,
    );
  }

  /// Converts this record instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'babyId': babyId,
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'breathingRate': breathingRate,
      'bodyTemperature': bodyTemperature,
      'roomTemperature': roomTemperature,
      'humidity': humidity,
      'movementDetected': movementDetected,
      'cryDetected': cryDetected,
      'sleepStage': sleepStage,
      'airQuality': airQuality,
      'batteryLevel': batteryLevel,
    };
  }

  @override
  List<Object?> get props => [
        id,
        deviceId,
        babyId,
        timestamp,
        heartRate,
        breathingRate,
        bodyTemperature,
        roomTemperature,
        humidity,
        movementDetected,
        cryDetected,
        sleepStage,
        airQuality,
        batteryLevel,
      ];
}
