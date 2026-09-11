import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/providers.dart';
import '../../../../domain/repositories/baby_repository.dart';
import '../../../../domain/repositories/device_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../shared/models/user_session.dart';
import '../../authentication/presentation/providers/auth_provider.dart';

enum OnboardingStep {
  welcome,
  profileSetup,
  babyRegister,
  devicePairing,
  caregiverSetup,
  completed,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final bool isLoading;

  const OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.isLoading = true,
  });

  bool get isCompleted => currentStep == OnboardingStep.completed;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ProfileRepository _profileRepo;
  final BabyRepository _babyRepo;
  final DeviceRepository _deviceRepo;
  final SharedPreferences _prefs;
  final String? _userEmail;
  final UserRole? _userRole;

  OnboardingNotifier({
    required ProfileRepository profileRepo,
    required BabyRepository babyRepo,
    required DeviceRepository deviceRepo,
    required SharedPreferences prefs,
    String? userEmail,
    UserRole? userRole,
  })  : _profileRepo = profileRepo,
        _babyRepo = babyRepo,
        _deviceRepo = deviceRepo,
        _prefs = prefs,
        _userEmail = userEmail,
        _userRole = userRole,
        super(const OnboardingState()) {
    checkOnboardingStatus();
  }

  static const String _welcomeKey = 'maatriva_welcome_completed';
  static const String _onboardingKey = 'maatriva_onboarding_completed';

  Future<void> checkOnboardingStatus() async {
    final userEmail = _userEmail;

    if (userEmail == null || userEmail.isEmpty) {
      state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
      return;
    }

    if (_userRole == UserRole.caregiver) {
      if (userEmail.isNotEmpty) {
        await _prefs.setBool('caregiver_setup_completed_$userEmail', true);
        await _prefs.setBool('${_onboardingKey}_$userEmail', true);
      }
      await _prefs.setBool(_welcomeKey, true);
      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
      return;
    }

    final userDone = _prefs.getBool('${_onboardingKey}_$userEmail') ?? false;

    if (userDone) {
      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {

      final isWelcomeDone = (_prefs.getBool(_welcomeKey) ?? false) || (userEmail != null && (_prefs.getBool('${_welcomeKey}_$userEmail') ?? false));

      try {
        final profile = await _profileRepo.getProfile();
        final hasProfileName = profile.parentName.isNotEmpty && profile.parentName != 'No Name Set';

        if (!isWelcomeDone) {
          debugPrint('[Onboarding] Welcome slides not completed yet for $userEmail. Showing Welcome step.');
          state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
          return;
        }

        if (!hasProfileName) {
          debugPrint('[Onboarding] Parent profile incomplete for $userEmail. Showing Profile Setup step.');
          state = state.copyWith(currentStep: OnboardingStep.profileSetup, isLoading: false);
          return;
        }

        final babies = await _babyRepo.getBabies();
        if (babies.isEmpty) {
          debugPrint('[Onboarding] Parent has 0 babies in database for $userEmail. Showing Baby Registration step.');
          state = state.copyWith(currentStep: OnboardingStep.babyRegister, isLoading: false);
          return;
        }

        final devices = await _deviceRepo.getDevices();
        if (devices.isEmpty) {
          debugPrint('[Onboarding] Parent has baby registered but 0 paired devices for $userEmail. Showing Device Pairing step.');
          state = state.copyWith(currentStep: OnboardingStep.devicePairing, isLoading: false);
          return;
        }

        debugPrint('[Onboarding] Parent $userEmail has completed welcome, profile, baby, and ${devices.length} paired device(s). Onboarding completed.');
        await _prefs.setBool('${_onboardingKey}_$userEmail', true);
        await _prefs.setBool('${_welcomeKey}_$userEmail', true);
        await _prefs.setBool(_welcomeKey, true);
        state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
        return;
      } catch (e) {
        debugPrint('[Onboarding] Error checking database profile/babies/devices: $e');
        state = state.copyWith(currentStep: OnboardingStep.profileSetup, isLoading: false);
      }
    } catch (e) {
      debugPrint('OnboardingNotifier checkStatus error: $e');
      state = state.copyWith(currentStep: OnboardingStep.profileSetup, isLoading: false);
    }
  }

  Future<void> completeCaregiverSetup({
    required String name,
    required String phone,
  }) async {
    final userEmail = _userEmail;
    if (userEmail != null) {
      await _prefs.setBool('caregiver_setup_completed_$userEmail', true);
      await _prefs.setBool('${_onboardingKey}_$userEmail', true);
      await _prefs.setBool(_welcomeKey, true);
    }
    try {
      final profile = await _profileRepo.getProfile();
      final updated = profile.copyWith(
        parentName: name,
        parentPhone: phone,
        relationship: 'Caregiver',
      );
      await _profileRepo.updateProfile(updated);
    } catch (_) {}

    state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
  }

  Future<void> completeWelcome() async {
    final userEmail = _userEmail;
    await _prefs.setBool(_welcomeKey, true);
    if (userEmail != null && userEmail.isNotEmpty) {
      await _prefs.setBool('${_welcomeKey}_$userEmail', true);
    }
    state = state.copyWith(currentStep: OnboardingStep.profileSetup, isLoading: false);
  }

  Future<void> completeOnboarding() async {
    final userEmail = _userEmail;
    await _prefs.setBool(_welcomeKey, true);
    await _prefs.setBool(_onboardingKey, true);
    if (userEmail != null && userEmail.isNotEmpty) {
      await _prefs.setBool('${_onboardingKey}_$userEmail', true);
      await _prefs.setBool('${_welcomeKey}_$userEmail', true);
      await _prefs.setBool('caregiver_setup_completed_$userEmail', true);
    }
    state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
  }

  void nextStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  Future<void> skipDevicePairing() async {
    await checkOnboardingStatus();
  }

  void resetOnboarding() async {
    await _prefs.remove(_welcomeKey);
    await _prefs.remove(_onboardingKey);
    if (_userEmail != null) {
      await _prefs.remove('${_onboardingKey}_$_userEmail');
    }
    await checkOnboardingStatus();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final babyRepo = ref.watch(babyRepositoryProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  final authState = ref.watch(authNotifierProvider);
  final email = authState.session?.email;
  final role = authState.session?.role;

  return OnboardingNotifier(
    profileRepo: profileRepo,
    babyRepo: babyRepo,
    deviceRepo: deviceRepo,
    prefs: prefs,
    userEmail: email,
    userRole: role,
  );
});
