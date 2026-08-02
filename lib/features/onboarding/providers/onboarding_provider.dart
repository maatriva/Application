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
    final globalDone = _prefs.getBool(_onboardingKey) ?? false;
    final userEmail = _userEmail;
    final userDone = userEmail != null && userEmail.isNotEmpty
        ? (_prefs.getBool('${_onboardingKey}_$userEmail') ?? false)
        : false;

    if (globalDone || userDone) {
      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
      return;
    }

    if (userEmail == null || userEmail.isEmpty) {
      state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      if (_userRole == UserRole.caregiver) {
        final caregiverDone = _prefs.getBool('caregiver_setup_completed_$userEmail') ?? false;
        if (!caregiverDone) {
          state = state.copyWith(currentStep: OnboardingStep.caregiverSetup, isLoading: false);
          return;
        }
        await _prefs.setBool('${_onboardingKey}_$userEmail', true);
        await _prefs.setBool(_welcomeKey, true);
        state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
        return;
      }

      final welcomeCompleted = _prefs.getBool(_welcomeKey) ?? false;
      if (!welcomeCompleted) {
        state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
        return;
      }

      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
    } catch (e) {
      debugPrint('OnboardingNotifier checkStatus error: $e');
      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
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
      await _prefs.setBool('${_onboardingKey}_$userEmail', true);
    }
    await _prefs.setBool(_onboardingKey, true);
    state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
  }

  Future<void> completeOnboarding() async {
    final userEmail = _userEmail;
    await _prefs.setBool(_welcomeKey, true);
    if (userEmail != null && userEmail.isNotEmpty) {
      await _prefs.setBool('${_onboardingKey}_$userEmail', true);
    }
    await _prefs.setBool(_onboardingKey, true);
    state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
  }

  void nextStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  Future<void> skipDevicePairing() async {
    if (_userEmail != null) {
      await _prefs.setBool('${_onboardingKey}_$_userEmail', true);
    }
    state = state.copyWith(currentStep: OnboardingStep.completed);
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
