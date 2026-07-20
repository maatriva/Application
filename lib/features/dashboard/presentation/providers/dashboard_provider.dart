import 'package:flutter_riverpod/flutter_riverpod.dart';

class BabyMetrics {
  final String motherName;
  final String babyStatus;
  final String connectivity;
  final String health;
  final double temperature;
  final int heartRate;
  final double sleepHours;
  final int cryCount;
  final String aiInsight;
  final bool isLoadingInsight;

  BabyMetrics({
    required this.motherName,
    required this.babyStatus,
    required this.connectivity,
    required this.health,
    required this.temperature,
    required this.heartRate,
    required this.sleepHours,
    required this.cryCount,
    required this.aiInsight,
    this.isLoadingInsight = false,
  });

  BabyMetrics copyWith({
    String? motherName,
    String? babyStatus,
    String? connectivity,
    String? health,
    double? temperature,
    int? heartRate,
    double? sleepHours,
    int? cryCount,
    String? aiInsight,
    bool? isLoadingInsight,
  }) {
    return BabyMetrics(
      motherName: motherName ?? this.motherName,
      babyStatus: babyStatus ?? this.babyStatus,
      connectivity: connectivity ?? this.connectivity,
      health: health ?? this.health,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      sleepHours: sleepHours ?? this.sleepHours,
      cryCount: cryCount ?? this.cryCount,
      aiInsight: aiInsight ?? this.aiInsight,
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
    );
  }
}

class DashboardNotifier extends StateNotifier<BabyMetrics> {
  DashboardNotifier()
    : super(
        BabyMetrics(
          motherName: 'Sarah',
          babyStatus: 'Sleeping',
          connectivity: 'Connected',
          health: 'Healthy',
          temperature: 24.0,
          heartRate: 115,
          sleepHours: 8.2,
          cryCount: 2,
          aiInsight:
              'Your baby had a peaceful sleep for 8 hours. This indicates the current nursery rhythm is optimal for healthy development.',
        ),
      );

  void updateBabyStatus(String status) {
    state = state.copyWith(babyStatus: status);
  }

  void updateBiometrics({double? temp, int? hr, double? sleep, int? cries}) {
    state = state.copyWith(
      temperature: temp ?? state.temperature,
      heartRate: hr ?? state.heartRate,
      sleepHours: sleep ?? state.sleepHours,
      cryCount: cries ?? state.cryCount,
    );
  }

  Future<void> refreshAIInsight() async {
    state = state.copyWith(isLoadingInsight: true);

    // Simulate API delay for natural UI transition
    await Future.delayed(const Duration(seconds: 1));

    String statusWord = state.babyStatus.toLowerCase();
    String newInsight =
        "Your baby is currently $statusWord. "
        "With a stable heart rate of ${state.heartRate} bpm and temperature at ${state.temperature}°C, the ambient parameters are perfect. "
        "Continue maintaining the current white noise level.";

    state = state.copyWith(aiInsight: newInsight, isLoadingInsight: false);
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, BabyMetrics>(
  (ref) {
    return DashboardNotifier();
  },
);
