import 'package:equatable/equatable.dart';
import '../enums/sensor_enums.dart';

/// Represents clustered physiological and health vitals telemetry for the baby.
class HealthPayload extends Equatable {
  /// Unique identifier of the primary wearable device (e.g., "HR-SOCK-02").
  final String deviceId;

  /// Cradle or room identifier.
  final String cradleId;

  /// Infant heart rate in beats per minute (BPM) (e.g., 122).
  final int heartRate;

  /// Infant respiration frequency in breaths per minute (brpm) (e.g., 34).
  final int breathingRate;

  /// Infant skin/body temperature in Celsius (e.g. 36.8).
  final double bodyTemperature;

  /// Blood oxygen saturation percentage (0-100) (e.g. 98). Null if not supported/offline.
  final int? spo2;

  /// Sleeping status stage ("rem", "deep_sleep", "light_sleep", "awake").
  final String sleepStage;

  /// Sleeping orientation posture ("supine", "prone", "side", "unknown").
  final String babyPosition;

  /// Telemetry reading data quality classification.
  final SensorQuality quality;

  /// Wearable sensor battery percentage (0-100). Null if charging/plugged.
  final int? battery;

  /// Bluetooth RSSI signal strength (in dBm).
  final int signalStrength;

  /// Core operational status of the health wearable.
  final SensorStatus status;

  /// Local recording timestamp.
  final DateTime timestamp;

  /// Monotonically increasing message sequence index.
  final int sequenceNumber;

  const HealthPayload({
    required this.deviceId,
    required this.cradleId,
    required this.heartRate,
    required this.breathingRate,
    required this.bodyTemperature,
    this.spo2,
    required this.sleepStage,
    required this.babyPosition,
    required this.quality,
    this.battery,
    required this.signalStrength,
    required this.status,
    required this.timestamp,
    required this.sequenceNumber,
  });

  /// Factory constructor to instantiate a health payload from JSON.
  factory HealthPayload.fromJson(Map<String, dynamic> json) {
    return HealthPayload(
      deviceId: json['deviceId'] as String? ?? '',
      cradleId: json['cradleId'] as String? ?? json['roomId'] as String? ?? '',
      heartRate: json['heartRate'] as int? ?? 0,
      breathingRate: json['breathingRate'] as int? ?? 0,
      bodyTemperature: (json['bodyTemperature'] as num?)?.toDouble() ?? 0.0,
      spo2: json['spo2'] as int?,
      sleepStage: json['sleepStage'] as String? ?? 'unknown',
      babyPosition: json['babyPosition'] as String? ?? 'unknown',
      quality: SensorQuality.fromJson(json['quality'] as String? ?? ''),
      battery: json['battery'] as int?,
      signalStrength: json['signalStrength'] as int? ?? 0,
      status: SensorStatus.fromJson(json['status'] as String? ?? ''),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      sequenceNumber: json['sequenceNumber'] as int? ?? 0,
    );
  }

  /// Converts this model instance into a standard JSON dictionary.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'cradleId': cradleId,
      'heartRate': heartRate,
      'breathingRate': breathingRate,
      'bodyTemperature': bodyTemperature,
      if (spo2 != null) 'spo2': spo2,
      'sleepStage': sleepStage,
      'babyPosition': babyPosition,
      'quality': quality.toJson(),
      if (battery != null) 'battery': battery,
      'signalStrength': signalStrength,
      'status': status.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'sequenceNumber': sequenceNumber,
    };
  }

  /// Creates a copy of this payload with modified parameters.
  HealthPayload copyWith({
    String? deviceId,
    String? cradleId,
    int? heartRate,
    int? breathingRate,
    double? bodyTemperature,
    int? spo2,
    String? sleepStage,
    String? babyPosition,
    SensorQuality? quality,
    int? battery,
    int? signalStrength,
    SensorStatus? status,
    DateTime? timestamp,
    int? sequenceNumber,
  }) {
    return HealthPayload(
      deviceId: deviceId ?? this.deviceId,
      cradleId: cradleId ?? this.cradleId,
      heartRate: heartRate ?? this.heartRate,
      breathingRate: breathingRate ?? this.breathingRate,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      spo2: spo2 ?? this.spo2,
      sleepStage: sleepStage ?? this.sleepStage,
      babyPosition: babyPosition ?? this.babyPosition,
      quality: quality ?? this.quality,
      battery: battery ?? this.battery,
      signalStrength: signalStrength ?? this.signalStrength,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    cradleId,
    heartRate,
    breathingRate,
    bodyTemperature,
    spo2,
    sleepStage,
    babyPosition,
    quality,
    battery,
    signalStrength,
    status,
    timestamp,
    sequenceNumber,
  ];
}
