import 'package:flutter_riverpod/flutter_riverpod.dart';

class VaccineRecord {
  final String id;
  final String name;
  final String ageDue;
  final String status; // 'Administered', 'Pending', 'Overdue'
  final String dateAdministered;

  VaccineRecord({
    required this.id,
    required this.name,
    required this.ageDue,
    required this.status,
    required this.dateAdministered,
  });

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
}

class ConnectedDevice {
  final String id;
  final String name;
  final String type; // 'Camera', 'Smart Sock', 'Hub', 'Soothe Rest'
  final bool isConnected;
  final int batteryLevel; // -1 if not applicable

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isConnected,
    required this.batteryLevel,
  });

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
}

class ProfileState {
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String parentAvatar;

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

  ProfileState({
    required this.parentName,
    required this.parentEmail,
    required this.parentPhone,
    required this.parentAvatar,
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

  ProfileState copyWith({
    String? parentName,
    String? parentEmail,
    String? parentPhone,
    String? parentAvatar,
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
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
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
      abnormalHeartRateAlerts:
          abnormalHeartRateAlerts ?? this.abnormalHeartRateAlerts,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      shareDataWithPediatrician:
          shareDataWithPediatrician ?? this.shareDataWithPediatrician,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier()
    : super(
        ProfileState(
          parentName: 'Sarah Johnson',
          parentEmail: 'sarah.johnson@maatriva.com',
          parentPhone: '+1 (555) 342-9841',
          parentAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=256',
          partnerName: 'David Johnson',
          partnerPhone: '+1 (555) 342-9842',
          emergencyContactName: 'Grandma Martha',
          emergencyContactPhone: '+1 (555) 987-6543',
          babyName: 'Chloe',
          babyDob: 'October 12, 2025',
          babyGender: 'Female',
          babyWeight: 6.4,
          babyHeight: 62.0,
          babyAvatar:
              'https://images.unsplash.com/photo-1519689680058-324335c77ebe?auto=format&fit=crop&q=80&w=256',
          allergies: 'None diagnosed. Peanut monitoring in progress.',
          pediatricianName: 'Dr. Evelyn Carter',
          pediatricianPhone: '+1 (555) 123-4567',
          vaccines: [
            VaccineRecord(
              id: 'v1',
              name: 'Hepatitis B (HepB)',
              ageDue: 'Birth',
              status: 'Administered',
              dateAdministered: '10/12/2025',
            ),
            VaccineRecord(
              id: 'v2',
              name: 'Rotavirus (RV)',
              ageDue: '2 Months',
              status: 'Administered',
              dateAdministered: '12/15/2025',
            ),
            VaccineRecord(
              id: 'v3',
              name: 'DTaP (Diphtheria, Tetanus, Pertussis)',
              ageDue: '2 Months',
              status: 'Administered',
              dateAdministered: '12/15/2025',
            ),
            VaccineRecord(
              id: 'v4',
              name: 'Haemophilus influenzae type b (Hib)',
              ageDue: '4 Months',
              status: 'Administered',
              dateAdministered: '02/16/2026',
            ),
            VaccineRecord(
              id: 'v5',
              name: 'Pneumococcal Conjugate (PCV13)',
              ageDue: '6 Months',
              status: 'Pending',
              dateAdministered: '--',
            ),
            VaccineRecord(
              id: 'v6',
              name: 'Inactivated Poliovirus (IPV)',
              ageDue: '6 Months',
              status: 'Pending',
              dateAdministered: '--',
            ),
          ],
          devices: [
            ConnectedDevice(
              id: 'd1',
              name: 'Maatriva Smart Cam 4K',
              type: 'Camera',
              isConnected: true,
              batteryLevel: -1,
            ),
            ConnectedDevice(
              id: 'd2',
              name: 'Maatriva Smart Sock V2',
              type: 'Smart Sock',
              isConnected: true,
              batteryLevel: 82,
            ),
            ConnectedDevice(
              id: 'd3',
              name: 'Maatriva Nursery Hub',
              type: 'Hub',
              isConnected: false,
              batteryLevel: -1,
            ),
          ],
          cryAlerts: true,
          tempAlerts: true,
          feedingReminders: false,
          sleepAnalysisWeekly: true,
          abnormalHeartRateAlerts: true,
          twoFactorAuth: false,
          biometricLogin: true,
          shareDataWithPediatrician: true,
        ),
      );

  void updateParentProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    state = state.copyWith(
      parentName: name,
      parentEmail: email,
      parentPhone: phone,
    );
  }

  void updateParentAvatar(String path) {
    state = state.copyWith(parentAvatar: path);
  }

  void updatePartnerDetails({
    required String partnerName,
    required String partnerPhone,
    required String emergencyName,
    required String emergencyPhone,
  }) {
    state = state.copyWith(
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      emergencyContactName: emergencyName,
      emergencyContactPhone: emergencyPhone,
    );
  }

  void updateBabyDetails({
    required String name,
    required String dob,
    required String gender,
    required double weight,
    required double height,
  }) {
    state = state.copyWith(
      babyName: name,
      babyDob: dob,
      babyGender: gender,
      babyWeight: weight,
      babyHeight: height,
    );
  }

  void updateMedicalDetails({
    required String allergies,
    required String pedName,
    required String pedPhone,
  }) {
    state = state.copyWith(
      allergies: allergies,
      pediatricianName: pedName,
      pediatricianPhone: pedPhone,
    );
  }

  void toggleVaccine(String id) {
    state = state.copyWith(
      vaccines: state.vaccines.map((v) {
        if (v.id == id) {
          final isDone = v.status == 'Administered';
          return v.copyWith(
            status: isDone ? 'Pending' : 'Administered',
            dateAdministered: isDone ? '--' : _getCurrentFormattedDate(),
          );
        }
        return v;
      }).toList(),
    );
  }

  void toggleDeviceConnection(String id) {
    state = state.copyWith(
      devices: state.devices.map((d) {
        if (d.id == id) {
          return d.copyWith(isConnected: !d.isConnected);
        }
        return d;
      }).toList(),
    );
  }

  void toggleNotificationPreference(String type) {
    switch (type) {
      case 'cryAlerts':
        state = state.copyWith(cryAlerts: !state.cryAlerts);
        break;
      case 'tempAlerts':
        state = state.copyWith(tempAlerts: !state.tempAlerts);
        break;
      case 'feedingReminders':
        state = state.copyWith(feedingReminders: !state.feedingReminders);
        break;
      case 'sleepAnalysisWeekly':
        state = state.copyWith(sleepAnalysisWeekly: !state.sleepAnalysisWeekly);
        break;
      case 'abnormalHeartRateAlerts':
        state = state.copyWith(
          abnormalHeartRateAlerts: !state.abnormalHeartRateAlerts,
        );
        break;
    }
  }

  void togglePrivacyPreference(String type) {
    switch (type) {
      case 'twoFactorAuth':
        state = state.copyWith(twoFactorAuth: !state.twoFactorAuth);
        break;
      case 'biometricLogin':
        state = state.copyWith(biometricLogin: !state.biometricLogin);
        break;
      case 'shareDataWithPediatrician':
        state = state.copyWith(
          shareDataWithPediatrician: !state.shareDataWithPediatrician,
        );
        break;
    }
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
