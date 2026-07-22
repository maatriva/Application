import 'package:equatable/equatable.dart';
import '../enums/sensor_enums.dart';

/// Represents details of a registered device or sensor hub in the MAATRIVA ecosystem.
class DeviceInfo extends Equatable {
  /// Unique identifier of the device (e.g. "HR-SOCK-02").
  final String deviceId;

  /// Human-readable name (e.g. "Heart Rate Smart Sock").
  final String deviceName;

  /// Sub-type of device or sensor class (e.g. "heart_rate_sensor").
  final String type;

  /// Semantic version of device firmware.
  final String firmwareVersion;

  /// Protocol used for connection ("BLE", "Wi-Fi", etc.).
  final String protocol;

  /// Battery percentage (0-100), or null if plugged in.
  final int? battery;

  /// Indicates if this device is paired with the current user's cradle.
  final bool paired;

  /// The last recorded communication timestamp.
  final DateTime lastSeen;

  /// Current network status of the device.
  final SensorStatus status;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.firmwareVersion,
    required this.protocol,
    this.battery,
    required this.paired,
    required this.lastSeen,
    required this.status,
  });

  /// Factory constructor to instantiate device info from a JSON dictionary.
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      firmwareVersion: json['firmwareVersion'] as String? ?? '',
      protocol: json['protocol'] as String? ?? '',
      battery: json['battery'] as int?,
      paired: json['paired'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
      status: SensorStatus.fromJson(json['status'] as String? ?? ''),
    );
  }

  /// Converts this model instance into a standard JSON dictionary.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'type': type,
      'firmwareVersion': firmwareVersion,
      'protocol': protocol,
      if (battery != null) 'battery': battery,
      'paired': paired,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status.toJson(),
    };
  }

  /// Creates a copy of this device registry record with modified parameters.
  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? type,
    String? firmwareVersion,
    String? protocol,
    int? battery,
    bool? paired,
    DateTime? lastSeen,
    SensorStatus? status,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      protocol: protocol ?? this.protocol,
      battery: battery ?? this.battery,
      paired: paired ?? this.paired,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    type,
    firmwareVersion,
    protocol,
    battery,
    paired,
    lastSeen,
    status,
  ];
}
