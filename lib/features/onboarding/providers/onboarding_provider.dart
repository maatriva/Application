import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/providers.dart';
import '../../../../domain/repositories/baby_repository.dart';
import '../../../../domain/repositories/device_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../authentication/presentation/providers/auth_provider.dart';

enum OnboardingStep {
  welcome,
  profileSetup,
  babyRegister,
  devicePairing,
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

  OnboardingNotifier({
    required ProfileRepository profileRepo,
    required BabyRepository babyRepo,
    required DeviceRepository deviceRepo,
    required SharedPreferences prefs,
    String? userEmail,
  })  : _profileRepo = profileRepo,
        _babyRepo = babyRepo,
        _deviceRepo = deviceRepo,
        _prefs = prefs,
        _userEmail = userEmail,
        super(const OnboardingState()) {
    checkOnboardingStatus();
  }

  static const String _welcomeKey = 'maatriva_welcome_completed';
  static const String _onboardingKey = 'maatriva_onboarding_completed';

  Future<void> checkOnboardingStatus() async {
    if (_userEmail == null) {
      state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      // 1. Check local preference cache first (essential for offline fallback support)
      final onboardingCompleted = _prefs.getBool('${_onboardingKey}_$_userEmail') ?? false;

      // 2. Query backend babies list (backend as the source of truth)
      List<dynamic> babies = [];
      bool hasNetworkError = false;
      try {
        babies = await _babyRepo.getBabies();
      } catch (e) {
        hasNetworkError = true;
        print('OnboardingNotifier getBabies error: $e');
      }

      if (!hasNetworkError) {
        if (babies.isNotEmpty) {
          // Parent profile exists because babies are registered on the backend
          await _prefs.setBool('${_onboardingKey}_$_userEmail', true);
          await _prefs.setBool(_welcomeKey, true);

          final profile = await _profileRepo.getProfile();
          if (profile.parentPhone.isEmpty || profile.relationship.isEmpty) {
            final updatedProfile = profile.copyWith(
              parentPhone: 'Verified',
              relationship: 'Parent',
            );
            await _profileRepo.updateProfile(updatedProfile);
          }

          state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
          return;
        }
      } else {
        // Handle network failures gracefully by relying on local SharedPreferences if already completed
        if (onboardingCompleted) {
          state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
          return;
        }
      }

      // If we are here, either they have no babies (new user) or they had a network error and are not onboarded locally
      // For new users, we continue through onboarding steps
      final welcomeCompleted = _prefs.getBool(_welcomeKey) ?? false;
      if (!welcomeCompleted) {
        state = state.copyWith(currentStep: OnboardingStep.welcome, isLoading: false);
        return;
      }

      // Check if profile is incomplete
      final profile = await _profileRepo.getProfile();
      if (profile.parentPhone.isEmpty || profile.relationship.isEmpty) {
        state = state.copyWith(currentStep: OnboardingStep.profileSetup, isLoading: false);
        return;
      }

      // Check if any baby is registered
      if (babies.isEmpty && !hasNetworkError) {
        state = state.copyWith(currentStep: OnboardingStep.babyRegister, isLoading: false);
        return;
      }

      // Check if any device is paired
      final devices = await _deviceRepo.getDevices();
      if (devices.isEmpty) {
        state = state.copyWith(currentStep: OnboardingStep.devicePairing, isLoading: false);
        return;
      }

      // All onboarding steps completed
      await _prefs.setBool('${_onboardingKey}_$_userEmail', true);
      state = state.copyWith(currentStep: OnboardingStep.completed, isLoading: false);
    } catch (e) {
      print('OnboardingNotifier checkStatus error: $e');
      final onboardingCompleted = _prefs.getBool('${_onboardingKey}_$_userEmail') ?? false;
      state = state.copyWith(
        currentStep: onboardingCompleted ? OnboardingStep.completed : OnboardingStep.welcome,
        isLoading: false,
      );
    }
  }

  Future<void> completeWelcome() async {
    await _prefs.setBool(_welcomeKey, true);
    await checkOnboardingStatus();
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

  return OnboardingNotifier(
    profileRepo: profileRepo,
    babyRepo: babyRepo,
    deviceRepo: deviceRepo,
    prefs: prefs,
    userEmail: email,
  );
});
