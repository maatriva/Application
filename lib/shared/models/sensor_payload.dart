import 'package:equatable/equatable.dart';
import '../enums/sensor_enums.dart';

/// Represents a standard telemetry packet emitted by a sensor in the MAATRIVA ecosystem.
class SensorPayload extends Equatable {
  /// Unique identifier of the physical hardware device (e.g. "HR-SOCK-02").
  final String deviceId;

  /// Identifier of the specific sensor unit on the device (e.g. "PPG-01").
  final String sensorId;

  /// The category/type of telemetry being reported.
  final SensorType type;

  /// The sensor reading value. Can be [double], [int], [String], or a [Map].
  final dynamic value;

  /// The unit of measurement (e.g., "bpm", "C", "%").
  final String unit;

  /// Time when the telemetry was recorded at the source.
  final DateTime timestamp;

  /// The perceived accuracy or validation rating of this reading.
  final SensorQuality quality;

  /// Battery percentage (0 to 100). Null if not battery-powered or plugged in.
  final int? battery;

  /// Received Signal Strength Indicator (RSSI) in dBm (e.g., -54).
  final int signalStrength;

  /// Operational state of the device.
  final SensorStatus status;

  /// Semantic version of the device firmware (e.g., "1.0.5").
  final String firmwareVersion;

  /// Cradle/Room grouping identifier (e.g., "CRDL001").
  final String cradleId;

  /// Monotonically increasing sequence index for message integrity.
  final int sequenceNumber;

  /// Optional unstructured data dictionary for advanced telemetry payload extensions.
  final Map<String, dynamic>? metadata;

  const SensorPayload({
    required this.deviceId,
    required this.sensorId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.quality,
    this.battery,
    required this.signalStrength,
    required this.status,
    required this.firmwareVersion,
    required this.cradleId,
    required this.sequenceNumber,
    this.metadata,
  });

  /// Factory constructor to instantiate a payload from a JSON dictionary.
  factory SensorPayload.fromJson(Map<String, dynamic> json) {
    return SensorPayload(
      deviceId: json['deviceId'] as String? ?? '',
      sensorId: json['sensorId'] as String? ?? '',
      type: SensorType.fromJson(json['type'] as String? ?? ''),
      value: json['value'],
      unit: json['unit'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      quality: SensorQuality.fromJson(json['quality'] as String? ?? ''),
      battery: json['battery'] as int?,
      signalStrength: json['signalStrength'] as int? ?? 0,
      status: SensorStatus.fromJson(json['status'] as String? ?? ''),
      firmwareVersion: json['firmwareVersion'] as String? ?? '',
      cradleId: json['cradleId'] as String? ?? json['roomId'] as String? ?? '',
      sequenceNumber: json['sequenceNumber'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts this model instance into a standard JSON dictionary.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'sensorId': sensorId,
      'type': type.toJson(),
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.toJson(),
      if (battery != null) 'battery': battery,
      'signalStrength': signalStrength,
      'status': status.toJson(),
      'firmwareVersion': firmwareVersion,
      'cradleId': cradleId,
      'sequenceNumber': sequenceNumber,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates a copy of this payload with modified parameters.
  SensorPayload copyWith({
    String? deviceId,
    String? sensorId,
    SensorType? type,
    dynamic value,
    String? unit,
    DateTime? timestamp,
    SensorQuality? quality,
    int? battery,
    int? signalStrength,
    SensorStatus? status,
    String? firmwareVersion,
    String? cradleId,
    int? sequenceNumber,
    Map<String, dynamic>? metadata,
  }) {
    return SensorPayload(
      deviceId: deviceId ?? this.deviceId,
      sensorId: sensorId ?? this.sensorId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      quality: quality ?? this.quality,
      battery: battery ?? this.battery,
      signalStrength: signalStrength ?? this.signalStrength,
      status: status ?? this.status,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      cradleId: cradleId ?? this.cradleId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    sensorId,
    type,
    value,
    unit,
    timestamp,
    quality,
    battery,
    signalStrength,
    status,
    firmwareVersion,
    cradleId,
    sequenceNumber,
    metadata,
  ];
}
