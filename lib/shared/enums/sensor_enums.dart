/// Enums for MAATRIVA Smart Cradle IoT telemetry and status tracking.
library;

/// Represents the type of IoT sensors and modules in the MAATRIVA ecosystem.
enum SensorType {
  heartRate('heart_rate'),
  breathingRate('breathing_rate'),
  bodyTemperature('body_temperature'),
  roomTemperature('room_temperature'),
  humidity('humidity'),
  motion('motion'),
  babyPosition('baby_position'),
  cryDetection('cry_detection'),
  sleepStage('sleep_stage'),
  airQuality('air_quality'),
  gasDetection('gas_detection'),
  cameraStatus('camera_status'),
  heatingPadTemperature('heating_pad_temperature'),
  spo2('spo2'),
  mattressPressure('mattress_pressure'),
  swingSpeed('swing_speed'),
  babyMood('baby_mood'),
  unknown('unknown');

  final String jsonValue;
  const SensorType(this.jsonValue);

  /// Parse [value] into a [SensorType].
  static SensorType fromJson(String value) {
    return SensorType.values.firstWhere(
      (type) => type.jsonValue == value,
      orElse: () => SensorType.unknown,
    );
  }

  String toJson() => jsonValue;
}

/// Represents the data quality rating of a sensor read telemetry packet.
enum SensorQuality {
  good('good'),
  fair('fair'),
  poor('poor'),
  invalid('invalid'),
  unknown('unknown');

  final String jsonValue;
  const SensorQuality(this.jsonValue);

  /// Parse [value] into a [SensorQuality].
  static SensorQuality fromJson(String value) {
    return SensorQuality.values.firstWhere(
      (q) => q.jsonValue == value,
      orElse: () => SensorQuality.unknown,
    );
  }

  String toJson() => jsonValue;
}

/// Represents the operational status of an IoT device.
enum SensorStatus {
  online('online'),
  offline('offline'),
  maintenance('maintenance'),
  error('error'),
  unknown('unknown');

  final String jsonValue;
  const SensorStatus(this.jsonValue);

  /// Parse [value] into a [SensorStatus].
  static SensorStatus fromJson(String value) {
    return SensorStatus.values.firstWhere(
      (s) => s.jsonValue == value,
      orElse: () => SensorStatus.unknown,
    );
  }

  String toJson() => jsonValue;
}
