import 'package:equatable/equatable.dart';

/// Represents registered device configurations.
class ClientDeviceInfo extends Equatable {
  final String deviceId;
  final String deviceName;
  final String type;
  final String firmwareVersion;
  final String protocol;
  final int? battery;
  final String status;
  final DateTime lastSeen;
  final String? babyId;
  final String? registrationKey;

  const ClientDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.firmwareVersion,
    required this.protocol,
    this.battery,
    required this.status,
    required this.lastSeen,
    this.babyId,
    this.registrationKey,
  });

  factory ClientDeviceInfo.fromJson(Map<String, dynamic> json) {
    return ClientDeviceInfo(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      firmwareVersion: json['firmwareVersion'] as String? ?? '1.0.0',
      protocol: json['protocol'] as String? ?? 'Wi-Fi',
      battery: json['battery'] as int?,
      status: json['status'] as String? ?? 'offline',
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
      babyId: json['babyId'] as String?,
      registrationKey: json['registrationKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'type': type,
      'firmwareVersion': firmwareVersion,
      'protocol': protocol,
      if (battery != null) 'battery': battery,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
      if (babyId != null) 'babyId': babyId,
      if (registrationKey != null) 'registrationKey': registrationKey,
    };
  }

  ClientDeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? type,
    String? firmwareVersion,
    String? protocol,
    int? battery,
    String? status,
    DateTime? lastSeen,
    String? babyId,
    String? registrationKey,
  }) {
    return ClientDeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      protocol: protocol ?? this.protocol,
      battery: battery ?? this.battery,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      babyId: babyId ?? this.babyId,
      registrationKey: registrationKey ?? this.registrationKey,
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
        status,
        lastSeen,
        babyId,
        registrationKey,
      ];
}
