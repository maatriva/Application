import 'package:equatable/equatable.dart';

/// Represents a baby's vaccine record.
class VaccineRecord extends Equatable {
  final String id;
  final String name;
  final String ageDue;
  final String status; // 'Administered', 'Pending', 'Overdue'
  final String dateAdministered;

  const VaccineRecord({
    required this.id,
    required this.name,
    required this.ageDue,
    required this.status,
    required this.dateAdministered,
  });

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    return VaccineRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ageDue: json['ageDue'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      dateAdministered: json['dateAdministered'] as String? ?? '--',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ageDue': ageDue,
      'status': status,
      'dateAdministered': dateAdministered,
    };
  }

  VaccineRecord copyWith({
    String? id,
    String? name,
    String? ageDue,
    String? status,
    String? dateAdministered,
  }) {
    return VaccineRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      ageDue: ageDue ?? this.ageDue,
      status: status ?? this.status,
      dateAdministered: dateAdministered ?? this.dateAdministered,
    );
  }

  @override
  List<Object?> get props => [id, name, ageDue, status, dateAdministered];
}

/// Represents a connected peripheral device.
class ConnectedDevice extends Equatable {
  final String id;
  final String name;
  final String type; // 'Camera', 'Smart Sock', 'Hub', 'Soothe Rest'
  final bool isConnected;
  final int batteryLevel; // -1 if not applicable

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isConnected,
    required this.batteryLevel,
  });

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isConnected: json['isConnected'] as bool? ?? false,
      batteryLevel: json['batteryLevel'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isConnected': isConnected,
      'batteryLevel': batteryLevel,
    };
  }

  ConnectedDevice copyWith({
    String? id,
    String? name,
    String? type,
    bool? isConnected,
    int? batteryLevel,
  }) {
    return ConnectedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  @override
  List<Object?> get props => [id, name, type, isConnected, batteryLevel];
}

/// Represents the overall parent profile and preference configuration states.
class ProfileState extends Equatable {
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String parentAvatar;
  final String relationship; // Mother, Father, Guardian, Other

  final String partnerName;
  final String partnerPhone;
  final String emergencyContactName;
  final String emergencyContactPhone;

  final String babyName;
  final String babyDob;
  final String babyGender;
  final double babyWeight; // in kg
  final double babyHeight; // in cm
  final String babyAvatar;

  final String allergies;
  final String pediatricianName;
  final String pediatricianPhone;
  final List<VaccineRecord> vaccines;

  final List<ConnectedDevice> devices;

  // Notification Preferences
  final bool cryAlerts;
  final bool tempAlerts;
  final bool feedingReminders;
  final bool sleepAnalysisWeekly;
  final bool abnormalHeartRateAlerts;

  // Privacy & Security
  final bool twoFactorAuth;
  final bool biometricLogin;
  final bool shareDataWithPediatrician;

  const ProfileState({
    required this.parentName,
    required this.parentEmail,
    required this.parentPhone,
    required this.parentAvatar,
    required this.relationship,
    required this.partnerName,
    required this.partnerPhone,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.babyName,
    required this.babyDob,
    required this.babyGender,
    required this.babyWeight,
    required this.babyHeight,
    required this.babyAvatar,
    required this.allergies,
    required this.pediatricianName,
    required this.pediatricianPhone,
    required this.vaccines,
    required this.devices,
    required this.cryAlerts,
    required this.tempAlerts,
    required this.feedingReminders,
    required this.sleepAnalysisWeekly,
    required this.abnormalHeartRateAlerts,
    required this.twoFactorAuth,
    required this.biometricLogin,
    required this.shareDataWithPediatrician,
  });

  factory ProfileState.fromJson(Map<String, dynamic> json) {
    return ProfileState(
      parentName: json['parentName'] as String? ?? '',
      parentEmail: json['parentEmail'] as String? ?? '',
      parentPhone: json['parentPhone'] as String? ?? '',
      parentAvatar: json['parentAvatar'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      partnerName: json['partnerName'] as String? ?? '',
      partnerPhone: json['partnerPhone'] as String? ?? '',
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      babyName: json['babyName'] as String? ?? '',
      babyDob: json['babyDob'] as String? ?? '',
      babyGender: json['babyGender'] as String? ?? '',
      babyWeight: (json['babyWeight'] as num?)?.toDouble() ?? 0.0,
      babyHeight: (json['babyHeight'] as num?)?.toDouble() ?? 0.0,
      babyAvatar: json['babyAvatar'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      pediatricianName: json['pediatricianName'] as String? ?? '',
      pediatricianPhone: json['pediatricianPhone'] as String? ?? '',
      vaccines: (json['vaccines'] as List? ?? [])
          .map((v) => VaccineRecord.fromJson(v as Map<String, dynamic>))
          .toList(),
      devices: (json['devices'] as List? ?? [])
          .map((d) => ConnectedDevice.fromJson(d as Map<String, dynamic>))
          .toList(),
      cryAlerts: json['cryAlerts'] as bool? ?? true,
      tempAlerts: json['tempAlerts'] as bool? ?? true,
      feedingReminders: json['feedingReminders'] as bool? ?? false,
      sleepAnalysisWeekly: json['sleepAnalysisWeekly'] as bool? ?? true,
      abnormalHeartRateAlerts: json['abnormalHeartRateAlerts'] as bool? ?? true,
      twoFactorAuth: json['twoFactorAuth'] as bool? ?? false,
      biometricLogin: json['biometricLogin'] as bool? ?? true,
      shareDataWithPediatrician: json['shareDataWithPediatrician'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentName': parentName,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'parentAvatar': parentAvatar,
      'relationship': relationship,
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'babyName': babyName,
      'babyDob': babyDob,
      'babyGender': babyGender,
      'babyWeight': babyWeight,
      'babyHeight': babyHeight,
      'babyAvatar': babyAvatar,
      'allergies': allergies,
      'pediatricianName': pediatricianName,
      'pediatricianPhone': pediatricianPhone,
      'vaccines': vaccines.map((v) => v.toJson()).toList(),
      'devices': devices.map((d) => d.toJson()).toList(),
      'cryAlerts': cryAlerts,
      'tempAlerts': tempAlerts,
      'feedingReminders': feedingReminders,
      'sleepAnalysisWeekly': sleepAnalysisWeekly,
      'abnormalHeartRateAlerts': abnormalHeartRateAlerts,
      'twoFactorAuth': twoFactorAuth,
      'biometricLogin': biometricLogin,
      'shareDataWithPediatrician': shareDataWithPediatrician,
    };
  }

  ProfileState copyWith({
    String? parentName,
    String? parentEmail,
    String? parentPhone,
    String? parentAvatar,
    String? relationship,
    String? partnerName,
    String? partnerPhone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? babyName,
    String? babyDob,
    String? babyGender,
    double? babyWeight,
    double? babyHeight,
    String? babyAvatar,
    String? allergies,
    String? pediatricianName,
    String? pediatricianPhone,
    List<VaccineRecord>? vaccines,
    List<ConnectedDevice>? devices,
    bool? cryAlerts,
    bool? tempAlerts,
    bool? feedingReminders,
    bool? sleepAnalysisWeekly,
    bool? abnormalHeartRateAlerts,
    bool? twoFactorAuth,
    bool? biometricLogin,
    bool? shareDataWithPediatrician,
  }) {
    return ProfileState(
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      parentAvatar: parentAvatar ?? this.parentAvatar,
      relationship: relationship ?? this.relationship,
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      babyName: babyName ?? this.babyName,
      babyDob: babyDob ?? this.babyDob,
      babyGender: babyGender ?? this.babyGender,
      babyWeight: babyWeight ?? this.babyWeight,
      babyHeight: babyHeight ?? this.babyHeight,
      babyAvatar: babyAvatar ?? this.babyAvatar,
      allergies: allergies ?? this.allergies,
      pediatricianName: pediatricianName ?? this.pediatricianName,
      pediatricianPhone: pediatricianPhone ?? this.pediatricianPhone,
      vaccines: vaccines ?? this.vaccines,
      devices: devices ?? this.devices,
      cryAlerts: cryAlerts ?? this.cryAlerts,
      tempAlerts: tempAlerts ?? this.tempAlerts,
      feedingReminders: feedingReminders ?? this.feedingReminders,
      sleepAnalysisWeekly: sleepAnalysisWeekly ?? this.sleepAnalysisWeekly,
      abnormalHeartRateAlerts: abnormalHeartRateAlerts ?? this.abnormalHeartRateAlerts,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      shareDataWithPediatrician: shareDataWithPediatrician ?? this.shareDataWithPediatrician,
    );
  }

  @override
  List<Object?> get props => [
        parentName,
        parentEmail,
        parentPhone,
        parentAvatar,
        relationship,
        partnerName,
        partnerPhone,
        emergencyContactName,
        emergencyContactPhone,
        babyName,
        babyDob,
        babyGender,
        babyWeight,
        babyHeight,
        babyAvatar,
        allergies,
        pediatricianName,
        pediatricianPhone,
        vaccines,
        devices,
        cryAlerts,
        tempAlerts,
        feedingReminders,
        sleepAnalysisWeekly,
        abnormalHeartRateAlerts,
        twoFactorAuth,
        biometricLogin,
        shareDataWithPediatrician,
      ];
}
