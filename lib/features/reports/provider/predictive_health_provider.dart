import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChronicPattern {
  final String name;
  final int probability;
  final String description;
  final String evidence;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  ChronicPattern({
    required this.name,
    required this.probability,
    required this.description,
    required this.evidence,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class VitalStatus {
  final String name;
  final String status;
  final Color color;
  final IconData icon;

  VitalStatus({
    required this.name,
    required this.status,
    required this.color,
    required this.icon,
  });
}

class CorrelationPoint {
  final String day;
  final double heartRate;
  final double temperature;

  CorrelationPoint({
    required this.day,
    required this.heartRate,
    required this.temperature,
  });
}

class PreventiveRecommendation {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color iconBgColor;

  PreventiveRecommendation({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class PredictiveHealthState {
  final int stabilityIndex;
  final String diagnosticInsight;
  final List<VitalStatus> vitals;
  final List<ChronicPattern> chronicPatterns;
  final List<CorrelationPoint> trendData;
  final List<PreventiveRecommendation> recommendations;
  final bool isAnalyzing;

  PredictiveHealthState({
    required this.stabilityIndex,
    required this.diagnosticInsight,
    required this.vitals,
    required this.chronicPatterns,
    required this.trendData,
    required this.recommendations,
    required this.isAnalyzing,
  });

  PredictiveHealthState copyWith({
    int? stabilityIndex,
    String? diagnosticInsight,
    List<VitalStatus>? vitals,
    List<ChronicPattern>? chronicPatterns,
    List<CorrelationPoint>? trendData,
    List<PreventiveRecommendation>? recommendations,
    bool? isAnalyzing,
  }) {
    return PredictiveHealthState(
      stabilityIndex: stabilityIndex ?? this.stabilityIndex,
      diagnosticInsight: diagnosticInsight ?? this.diagnosticInsight,
      vitals: vitals ?? this.vitals,
      chronicPatterns: chronicPatterns ?? this.chronicPatterns,
      trendData: trendData ?? this.trendData,
      recommendations: recommendations ?? this.recommendations,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

class PredictiveHealthNotifier extends StateNotifier<PredictiveHealthState> {
  PredictiveHealthNotifier()
    : super(
        PredictiveHealthState(
          stabilityIndex: 82,
          diagnosticInsight:
              "Maatriva's analysis suggests a consistent pattern of night-time restlessness combined with slight temperature fluctuations. This pattern is often a precursor to teething or mild digestive sensitivity. We've noted increased cardiac variability during the 3 AM window over the last 4 nights.",
          vitals: [
            VitalStatus(
              name: 'Respiratory',
              status: 'Stable',
              color: const Color(0xFF10B981), // Emerald
              icon: Icons.air_rounded,
            ),
            VitalStatus(
              name: 'Cardiac',
              status: 'Normal',
              color: const Color(0xFF3B82F6), // Blue
              icon: Icons.favorite_rounded,
            ),
            VitalStatus(
              name: 'Temp',
              status: 'Fluctuating',
              color: const Color(0xFFEF4444), // Red
              icon: Icons.thermostat_rounded,
            ),
          ],
          chronicPatterns: [
            ChronicPattern(
              name: 'Chronic Sleep Fragmentation',
              probability: 68,
              description:
                  'Frequent micro-arousals detected without full waking. Sensor data shows 12% drop in deep sleep phase.',
              evidence: 'Sensor Evidence: Disrupted REM since Mar 12',
              icon: Icons.nights_stay_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBgColor: const Color(0xFFEFF6FF),
            ),
            ChronicPattern(
              name: 'Cyclic Fever Pattern',
              probability: 24,
              description:
                  'Temperature spikes detected approximately every 14 days. Likely biological growth spurts.',
              evidence: 'Evidence: Peaks at 101.2°F recurring',
              icon: Icons.thermostat_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
            ),
          ],
          trendData: [
            CorrelationPoint(day: '1', heartRate: 110, temperature: 36.4),
            CorrelationPoint(day: '5', heartRate: 120, temperature: 36.8),
            CorrelationPoint(day: '10', heartRate: 115, temperature: 36.5),
            CorrelationPoint(day: '15', heartRate: 125, temperature: 37.1),
            CorrelationPoint(day: '20', heartRate: 112, temperature: 36.7),
            CorrelationPoint(day: '25', heartRate: 118, temperature: 36.9),
            CorrelationPoint(day: '30', heartRate: 110, temperature: 36.4),
          ],
          recommendations: [
            PreventiveRecommendation(
              icon: Icons.opacity_rounded,
              text:
                  'Adjust nursery humidity to 50% to reduce nighttime respiratory stress.',
              iconColor: const Color(0xFF6E3DE0),
              iconBgColor: const Color(0xFFF3EDFA),
            ),
            PreventiveRecommendation(
              icon: Icons.health_and_safety_rounded,
              text:
                  'Consider a pediatric consult if cough patterns persist for 48 more hours.',
              iconColor: const Color(0xFF6E3DE0),
              iconBgColor: const Color(0xFFF3EDFA),
            ),
          ],
          isAnalyzing: false,
        ),
      );

  void runAIAnalysis() {
    state = state.copyWith(isAnalyzing: true);
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(
        isAnalyzing: false,
        stabilityIndex: 85,
        diagnosticInsight:
            "AI Update: Analysis completed. Recent readings show stabilization in cardiac rhythm during quiet sleep. Mild temperature variance remains, confirming typical teething progression. Continue monitoring nighttime room humidity.",
      );
    });
  }
}

final predictiveHealthProvider =
    StateNotifierProvider<PredictiveHealthNotifier, PredictiveHealthState>((
      ref,
    ) {
      return PredictiveHealthNotifier();
    });
