import 'package:equatable/equatable.dart';
import '../enums/sensor_enums.dart';

/// Represents clustered environmental and nursery climate telemetry.
class EnvironmentalPayload extends Equatable {
  /// Unique identifier of the gateway or sensor cluster reporting these vitals.
  final String deviceId;

  /// Cradle/Room grouping identifier (e.g., "CRDL001").
  final String cradleId;

  /// Ambient room temperature in Celsius (e.g. 24.2).
  final double roomTemperature;

  /// Ambient room relative humidity percentage (e.g. 45.5).
  final double humidity;

  /// Air Quality Index (AQI) rating (e.g., 35).
  final int airQuality;

  /// Combustible or toxic gas concentrations in Parts Per Million (PPM) (e.g., 1.2).
  final double gasLevel;

  /// Temperature of the cradle heating pad in Celsius. Null if disabled or offline.
  final double? heatingPadTemperature;

  /// Perceived reading quality of this telemetry cluster.
  final SensorQuality quality;

  /// Battery percentage of the sensor cluster, or null if powered by mains.
  final int? battery;

  /// Wi-Fi RSSI signal strength (in dBm).
  final int signalStrength;

  /// Core operational status of the cluster.
  final SensorStatus status;

  /// Local recording timestamp.
  final DateTime timestamp;

  /// Monotonically increasing message sequence number.
  final int sequenceNumber;

  const EnvironmentalPayload({
    required this.deviceId,
    required this.cradleId,
    required this.roomTemperature,
    required this.humidity,
    required this.airQuality,
    required this.gasLevel,
    this.heatingPadTemperature,
    required this.quality,
    this.battery,
    required this.signalStrength,
    required this.status,
    required this.timestamp,
    required this.sequenceNumber,
  });

  /// Factory constructor to instantiate an environmental payload from JSON.
  factory EnvironmentalPayload.fromJson(Map<String, dynamic> json) {
    return EnvironmentalPayload(
      deviceId: json['deviceId'] as String? ?? '',
      cradleId: json['cradleId'] as String? ?? json['roomId'] as String? ?? '',
      roomTemperature: (json['roomTemperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      airQuality: json['airQuality'] as int? ?? 0,
      gasLevel: (json['gasLevel'] as num?)?.toDouble() ?? 0.0,
      heatingPadTemperature: (json['heatingPadTemperature'] as num?)
          ?.toDouble(),
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
      'roomTemperature': roomTemperature,
      'humidity': humidity,
      'airQuality': airQuality,
      'gasLevel': gasLevel,
      if (heatingPadTemperature != null)
        'heatingPadTemperature': heatingPadTemperature,
      'quality': quality.toJson(),
      if (battery != null) 'battery': battery,
      'signalStrength': signalStrength,
      'status': status.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'sequenceNumber': sequenceNumber,
    };
  }

  /// Creates a copy of this payload with modified parameters.
  EnvironmentalPayload copyWith({
    String? deviceId,
    String? cradleId,
    double? roomTemperature,
    double? humidity,
    int? airQuality,
    double? gasLevel,
    double? heatingPadTemperature,
    SensorQuality? quality,
    int? battery,
    int? signalStrength,
    SensorStatus? status,
    DateTime? timestamp,
    int? sequenceNumber,
  }) {
    return EnvironmentalPayload(
      deviceId: deviceId ?? this.deviceId,
      cradleId: cradleId ?? this.cradleId,
      roomTemperature: roomTemperature ?? this.roomTemperature,
      humidity: humidity ?? this.humidity,
      airQuality: airQuality ?? this.airQuality,
      gasLevel: gasLevel ?? this.gasLevel,
      heatingPadTemperature:
          heatingPadTemperature ?? this.heatingPadTemperature,
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
    roomTemperature,
    humidity,
    airQuality,
    gasLevel,
    heatingPadTemperature,
    quality,
    battery,
    signalStrength,
    status,
    timestamp,
    sequenceNumber,
  ];
}
