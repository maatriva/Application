import 'package:equatable/equatable.dart';

/// User profile roles in the MAATRIVA ecosystem.
enum UserRole { parent, caregiver, doctor, admin }

/// Helper to parse roles from/to JSON string.
UserRole parseRole(String roleStr) {
  return UserRole.values.firstWhere(
    (e) => e.name == roleStr,
    orElse: () => UserRole.caregiver,
  );
}

/// Represents user credentials session details.
class UserSession extends Equatable {
  final String id;
  final String email;
  final UserRole role;

  const UserSession({
    required this.id,
    required this.email,
    required this.role,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parseRole(json['role'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
    };
  }

  @override
  List<Object?> get props => [id, email, role];
}

/// Represents a Baby Profile.
class BabyProfile extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final DateTime birthDate;
  final String gender;

  const BabyProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.birthDate,
    required this.gender,
  });

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    return BabyProfile(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      gender: json['gender'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
    };
  }

  @override
  List<Object?> get props => [id, parentId, name, birthDate, gender];
}

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
      sensorType: json['sensorType'] as String? ?? json['type'] as String? ?? '',
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

  @override
  List<Object?> get props => [sensorType, value, unit, quality, timestamp];
}

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

  @override
  List<Object?> get props => [id, severity, type, message, value, thresholdLimit, timestamp, acknowledged];
}

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
    };
  }

  @override
  List<Object?> get props => [deviceId, deviceName, type, firmwareVersion, protocol, battery, status, lastSeen, babyId];
}

/// Caregiver invitation mapping detail.
class CaregiverInvitation extends Equatable {
  final String invitationId;
  final String email;
  final String firstName;
  final String lastName;
  final String accessLevel;
  final String status;

  const CaregiverInvitation({
    required this.invitationId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.accessLevel,
    required this.status,
  });

  factory CaregiverInvitation.fromJson(Map<String, dynamic> json) {
    return CaregiverInvitation(
      invitationId: json['invitationId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      accessLevel: json['accessLevel'] as String? ?? 'monitor',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'accessLevel': accessLevel,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [invitationId, email, firstName, lastName, accessLevel, status];
}
