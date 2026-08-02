import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/providers.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../shared/models/profile.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepo;

  ProfileNotifier({required ProfileRepository profileRepo})
      : _profileRepo = profileRepo,
        super(
          const ProfileState(
            parentName: '',
            parentEmail: '',
            parentPhone: '',
            parentAvatar: '',
            relationship: '',
            partnerName: '',
            partnerPhone: '',
            emergencyContactName: '',
            emergencyContactPhone: '',
            babyName: '',
            babyDob: '',
            babyGender: '',
            babyWeight: 0.0,
            babyHeight: 0.0,
            babyAvatar: '',
            allergies: '',
            pediatricianName: '',
            pediatricianPhone: '',
            vaccines: [],
            devices: [],
            cryAlerts: true,
            tempAlerts: true,
            feedingReminders: false,
            sleepAnalysisWeekly: true,
            abnormalHeartRateAlerts: true,
            twoFactorAuth: false,
            biometricLogin: true,
            shareDataWithPediatrician: true,
          ),
        ) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await _profileRepo.getProfile();
      if (mounted) {
        state = profile;
        debugPrint('[PROFILE] ProfileNotifier state updated with profile for ${profile.parentName}.');
      }
    } catch (e) {
      debugPrint('[PROFILE] ProfileNotifier loadProfile error: $e');
    }
  }

  void updateParentProfile({
    required String name,
    required String email,
    required String phone,
    required String relationship,
  }) {
    state = state.copyWith(
      parentName: name,
      parentEmail: email,
      parentPhone: phone,
      relationship: relationship,
    );
    _persistState();
  }

  void updateParentAvatar(String path) {
    state = state.copyWith(parentAvatar: path);
    _persistState();
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
    _persistState();
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
    _persistState();
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
    _persistState();
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
    _persistState();
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
    _persistState();
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
    _persistState();
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
    _persistState();
  }

  Future<void> _persistState() async {
    try {
      await _profileRepo.updateProfile(state);
    } catch (_) {}
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(profileRepo: profileRepo);
});
