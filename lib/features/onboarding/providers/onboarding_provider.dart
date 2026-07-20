import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final bool isCompleted;

  const OnboardingState({this.isCompleted = false});

  OnboardingState copyWith({bool? isCompleted}) {
    return OnboardingState(isCompleted: isCompleted ?? this.isCompleted);
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState(isCompleted: false));

  void completeOnboarding() {
    state = state.copyWith(isCompleted: true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier();
    });
