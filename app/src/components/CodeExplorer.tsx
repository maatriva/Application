import React, { useState } from "react";
import { Folder, FileCode, Check, Copy, ChevronRight, ChevronDown, Layers, Smartphone } from "lucide-react";
import { FlutterFile } from "../types";

const flutterFilesList: FlutterFile[] = [
  {
    name: "pubspec.yaml",
    path: "pubspec.yaml",
    language: "yaml",
    description: "Declares project dependencies: flutter_riverpod, google_fonts, and flutter_screenutil.",
    content: `name: maatriva
description: "Maatriva - AI-Powered Smart Baby Monitoring Application"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.35.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  google_fonts: ^6.1.0
  flutter_screenutil: ^5.9.0
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true`
  },
  {
    name: "main.dart",
    path: "lib/main.dart",
    language: "dart",
    description: "App entrypoint wrapping the application in a Riverpod ProviderScope and bootstrapping the Material 3 app theme.",
    content: `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaatrivaApp(),
    ),
  );
}

class MaatrivaApp extends StatelessWidget {
  const MaatrivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maatriva Smart Baby Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}`
  },
  {
    name: "routes.dart",
    path: "lib/routes.dart",
    language: "dart",
    description: "App router configuration mapping features like Home, Predictive Health, and AI Assistant to GoRouter paths.",
    content: `import 'package:go_router/go_router.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';
import 'features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'features/health_reports/presentation/screens/predictive_health_screen.dart';
import 'features/shop/presentation/screens/shop_screen.dart';

final GoRouter goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/predictive-health',
      builder: (context, state) => const PredictiveHealthScreen(),
    ),
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
  ],
);`
  },
  {
    name: "colors.dart",
    path: "lib/theme/colors.dart",
    language: "dart",
    description: "Centralized color system. Avoids hardcoded values and defines the soft lavender palette and glowing shadows.",
    content: `import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Canvas
  static const Color background = Color(0xFFFBF8FD);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFEFEAF5);

  // Brand Colors
  static const Color primary = Color(0xFF6E3DE0);
  static const Color primaryLight = Color(0xFFEBE3FC);
  static const Color textPrimary = Color(0xFF1E0E3D);
  static const Color textSecondary = Color(0xFF655B75);

  // Status Chip Colors
  static const Color sleepBg = Color(0xFFE2F3EC);
  static const Color sleepText = Color(0xFF128054);
  
  static const Color healthBg = Color(0xFFF3EDFA);
  static const Color healthText = Color(0xFF8143D1);

  static const Color connectBg = Color(0xFFE5EFFB);
  static const Color connectText = Color(0xFF1866C5);

  // Today's Summary Circular Icon Backgrounds & Colors
  static const Color tempBg = Color(0xFFE8F0FE);
  static const Color tempIcon = Color(0xFF1A73E8);

  static const Color heartBg = Color(0xFFFDE8E8);
  static const Color heartIcon = Color(0xFFE02424);

  static const Color sleepProgressBg = Color(0xFFF3E8FF);
  static const Color sleepProgressIcon = Color(0xFF7E3AF2);

  static const Color cryBg = Color(0xFFE1F8F5);
  static const Color cryIcon = Color(0xFF0E9F6E);

  // Soft Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF5D2EC0).withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF5D2EC0).withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}`
  },
  {
    name: "typography.dart",
    path: "lib/theme/typography.dart",
    language: "dart",
    description: "Pairs Google Fonts' Playfair Display (Serif) with Inter (Sans-serif) for high-end mobile typography scale.",
    content: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayHeader => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionTitle => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get metricValue => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get metricUnit => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}`
  },
  {
    name: "app_theme.dart",
    path: "lib/theme/app_theme.dart",
    language: "dart",
    description: "Configures Material 3 ThemeData with our custom typography scale, color tokens, and custom card shapes.",
    content: `import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        background: AppColors.background,
        surface: AppColors.cardBg,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayHeader,
        titleLarge: AppTypography.sectionTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelMedium: AppTypography.labelMedium,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}`
  },
  {
    name: "dashboard_provider.dart",
    path: "lib/features/dashboard/presentation/providers/dashboard_provider.dart",
    language: "dart",
    description: "Riverpod StateNotifier providing clean, reactive state management and asynchronous mock AI insights generation.",
    content: `import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      : super(BabyMetrics(
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
        ));

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
    await Future.delayed(const Duration(seconds: 1));
    
    String statusWord = state.babyStatus.toLowerCase();
    String newInsight = "Your baby is currently $statusWord. "
        "With a stable heart rate of \${state.heartRate} bpm and temperature at \${state.temperature}°C, the ambient parameters are perfect. "
        "Continue maintaining the current white noise level.";
        
    state = state.copyWith(
      aiInsight: newInsight,
      isLoadingInsight: false,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, BabyMetrics>((ref) {
  return DashboardNotifier();
});`
  },
  {
    name: "predictive_health_provider.dart",
    path: "lib/features/health_reports/provider/predictive_health_provider.dart",
    language: "dart",
    description: "Riverpod state notifier managing stability scores, vitals telemetry status, and potential chronic illness probabilities.",
    content: `import 'package:flutter/material.dart';
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
      : super(PredictiveHealthState(
          stabilityIndex: 82,
          diagnosticInsight:
              "Maatriva's analysis suggests a consistent pattern of night-time restlessness combined with slight temperature fluctuations. This pattern is often a precursor to teething or mild digestive sensitivity. We've noted increased cardiac variability during the 3 AM window over the last 4 nights.",
          vitals: [
            VitalStatus(name: 'Respiratory', status: 'Stable', color: Color(0xFF10B981), icon: Icons.air_rounded),
            VitalStatus(name: 'Cardiac', status: 'Normal', color: Color(0xFF3B82F6), icon: Icons.favorite_rounded),
            VitalStatus(name: 'Temp', status: 'Fluctuating', color: Color(0xFFEF4444), icon: Icons.thermostat_rounded),
          ],
          chronicPatterns: [
            ChronicPattern(
              name: 'Chronic Sleep Fragmentation',
              probability: 68,
              description: 'Frequent micro-arousals detected without full waking. Sensor data shows 12% drop in deep sleep phase.',
              evidence: 'Sensor Evidence: Disrupted REM since Mar 12',
              icon: Icons.nights_stay_rounded,
              iconColor: Color(0xFF3B82F6),
              iconBgColor: Color(0xFFEFF6FF),
            ),
            ChronicPattern(
              name: 'Cyclic Fever Pattern',
              probability: 24,
              description: 'Temperature spikes detected approximately every 14 days. Likely biological growth spurts.',
              evidence: 'Evidence: Peaks at 101.2°F recurring',
              icon: Icons.thermostat_rounded,
              iconColor: Color(0xFF10B981),
              iconBgColor: Color(0xFFECFDF5),
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
              text: 'Adjust nursery humidity to 50% to reduce nighttime respiratory stress.',
              iconColor: Color(0xFF6E3DE0),
              iconBgColor: Color(0xFFF3EDFA),
            ),
            PreventiveRecommendation(
              icon: Icons.health_and_safety_rounded,
              text: 'Consider a pediatric consult if cough patterns persist for 48 more hours.',
              iconColor: Color(0xFF6E3DE0),
              iconBgColor: Color(0xFFF3EDFA),
            ),
          ],
          isAnalyzing: false,
        ));

  void runAIAnalysis() {
    state = state.copyWith(isAnalyzing: true);
    Future.delayed(Duration(seconds: 2), () {
      state = state.copyWith(
        isAnalyzing: false,
        stabilityIndex: 85,
        diagnosticInsight: "AI Update: Analysis completed. Recent readings show stabilization in cardiac rhythm during quiet sleep. Mild temperature variance remains, confirming typical teething progression.",
      );
    });
  }
}

final predictiveHealthProvider =
    StateNotifierProvider<PredictiveHealthNotifier, PredictiveHealthState>((ref) {
  return PredictiveHealthNotifier();
});`
  },
  {
    name: "home_screen.dart",
    path: "lib/features/dashboard/presentation/screens/home_screen.dart",
    language: "dart",
    description: "HomeScreen orchestrating the dashboard widgets. Follows the Single Responsibility Principle, containing zero inline layouts.",
    content: `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/status_chip.dart';
import '../widgets/live_camera_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/bottom_navigation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DashboardHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingSection(
              motherName: metrics.motherName,
              babyStatus: metrics.babyStatus,
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  StatusChip.sleeping(
                    onTap: () {
                      final nextStatus =
                          metrics.babyStatus == 'Sleeping' ? 'Awake' : 'Sleeping';
                      ref
                          .read(dashboardProvider.notifier)
                          .updateBabyStatus(nextStatus);
                      ref.read(dashboardProvider.notifier).refreshAIInsight();
                    },
                  ),
                  const SizedBox(width: 8),
                  StatusChip.healthy(),
                  const SizedBox(width: 8),
                  StatusChip.connected(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Baby Status',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 12),
            const LiveCameraCard(),
            const SizedBox(height: 28),
            Text(
              "Today's Summary",
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                SummaryCard(
                  label: 'Temperature',
                  value: '\${metrics.temperature.toInt()}',
                  unit: '°C',
                  icon: Icons.thermostat_outlined,
                  iconBgColor: AppColors.tempBg,
                  iconColor: AppColors.tempIcon,
                ),
                SummaryCard(
                  label: 'Heart Rate',
                  value: '\${metrics.heartRate}',
                  unit: 'bpm',
                  icon: Icons.favorite_border_rounded,
                  iconBgColor: AppColors.heartBg,
                  iconColor: AppColors.heartIcon,
                ),
                SummaryCard(
                  label: 'Sleep',
                  value: '\${metrics.sleepHours}',
                  unit: 'hrs',
                  icon: Icons.nights_stay_outlined,
                  iconBgColor: AppColors.sleepProgressBg,
                  iconColor: AppColors.sleepProgressIcon,
                ),
                SummaryCard(
                  label: 'Cry Count',
                  value: '\${metrics.cryCount}',
                  unit: '',
                  icon: Icons.face_retouching_natural_outlined,
                  iconBgColor: AppColors.cryBg,
                  iconColor: AppColors.cryIcon,
                ),
              ],
            ),
            const SizedBox(height: 28),
            AIInsightCard(
              insight: metrics.aiInsight,
              isLoading: metrics.isLoadingInsight,
              onRefresh: () {
                ref.read(dashboardProvider.notifier).refreshAIInsight();
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Quick Actions',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                QuickActionButton(
                  icon: Icons.videocam_outlined,
                  label: 'Live',
                  onTap: () {},
                ),
                QuickActionButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Assistant',
                  onTap: () {},
                ),
                QuickActionButton(
                  icon: Icons.favorite_border_rounded,
                  label: 'Predictive Health',
                  onTap: () {},
                ),
                QuickActionButton(
                  icon: Icons.medical_services_outlined,
                  label: 'Doctor',
                  onTap: () {},
                ),
                QuickActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
                QuickActionButton(
                  icon: Icons.music_note_outlined,
                  label: 'Music',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 2) {
            context.push('/predictive-health');
          } else if (index == 3) {
            context.push('/shop');
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
      ),
    );
  }
}`
  },
  {
    name: "predictive_health_screen.dart",
    path: "lib/features/health_reports/presentation/screens/predictive_health_screen.dart",
    language: "dart",
    description: "Predictive Health screen displaying baby vitals stability index, potential chronic illnesses, 30-day trends, and recommendations.",
    content: `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/colors.dart';
import '../../provider/predictive_health_provider.dart';
import '../../../dashboard/presentation/widgets/bottom_navigation.dart';

class PredictiveHealthScreen extends ConsumerStatefulWidget {
  const PredictiveHealthScreen({super.key});

  @override
  ConsumerState<PredictiveHealthScreen> createState() =>
      _PredictiveHealthScreenState();
}

class _PredictiveHealthScreenState extends ConsumerState<PredictiveHealthScreen> {
  bool _isPatternsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictiveHealthProvider);
    final notifier = ref.read(predictiveHealthProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FD),
      appBar: AppBar(
        title: const Text('Predictive Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 140.h),
            child: Column(
              children: [
                _buildStabilityIndexCard(state, notifier),
                SizedBox(height: 20.h),
                _buildVitalsRow(state),
                SizedBox(height: 24.h),
                _buildChronicPatternsSection(state),
                SizedBox(height: 24.h),
                _buildCorrelationTrendsSection(state),
                SizedBox(height: 24.h),
                _buildRecommendationsSection(state),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Consult Doctor'),
                ),
                BottomNavigation(
                  currentIndex: 2,
                  onTap: (index) {
                    if (index == 0) context.go('/');
                    if (index == 3) context.go('/shop');
                    if (index == 4) context.go('/ai-assistant');
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStabilityIndexCard(state, notifier) { /* ... Circular gauge & AI insights ... */ return Container(); }
  Widget _buildVitalsRow(state) { /* ... Respiratory / Cardiac / Temp ... */ return Container(); }
  Widget _buildChronicPatternsSection(state) { /* ... Sleep Fragmentation (68%) & Cyclic Fever (24%) ... */ return Container(); }
  Widget _buildCorrelationTrendsSection(state) { /* ... 30-Day side-by-side bar chart ... */ return Container(); }
  Widget _buildRecommendationsSection(state) { /* ... Humidity and consultation rules ... */ return Container(); }
}`
  },
  {
    name: "app_drawer.dart",
    path: "lib/features/dashboard/presentation/widgets/app_drawer.dart",
    language: "dart",
    description: "Sliding hamburger menu providing quick navigation to AI Assistant, Predictive Health, Music, and an About Us dialog.",
    content: `import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Sarah Johnson'),
            accountEmail: const Text('sarah.johnson@maatriva.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Assistant'),
            onTap: () {
              Navigator.pop(context);
              context.push('/ai-assistant');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: const Text('Predictive Health'),
            onTap: () {
              Navigator.pop(context);
              context.push('/predictive-health');
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Music Soother'),
            onTap: () {
              Navigator.pop(context);
              context.push('/music');
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Caregiver Access'),
            onTap: () {
              Navigator.pop(context);
              context.push('/caregiver-access');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Nursery Shop'),
            onTap: () {
              Navigator.pop(context);
              context.push('/shop');
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Live Camera Feed'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('About Maatriva'),
        content: Text('Maatriva is a premium, AI-powered smart baby monitoring ecosystem designed by pediatric specialists...'),
      ),
    );
  }
}`
  },
  {
    name: "dashboard_header.dart",
    path: "lib/features/dashboard/presentation/widgets/dashboard_header.dart",
    language: "dart",
    description: "Header component containing the hamburger menu trigger, localized app branding, and an elegant Material 3 notification bell.",
    content: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/colors.dart';

class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Maatriva',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}`
  },
  {
    name: "greeting_section.dart",
    path: "lib/features/dashboard/presentation/widgets/greeting_section.dart",
    language: "dart",
    description: "Renders the dynamic salutation and contextual parenting guidance text reflecting baby biometrics.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class GreetingSection extends StatelessWidget {
  final String motherName;
  final String babyStatus;

  const GreetingSection({
    super.key,
    required this.motherName,
    required this.babyStatus,
  });

  @override
  Widget build(BuildContext context) {
    String subtext = "Your little one is having a peaceful morning.";
    if (babyStatus.toLowerCase() == 'crying' || babyStatus.toLowerCase() == 'awake') {
      subtext = "Your little one is awake and needs your attention.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning, \$motherName',
          style: AppTypography.displayHeader,
        ),
        const SizedBox(height: 6),
        Text(
          subtext,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}`
  },
  {
    name: "status_chip.dart",
    path: "lib/features/dashboard/presentation/widgets/status_chip.dart",
    language: "dart",
    description: "Highly reusable capsule tag with options for solid dot indicators or system icons (shield, wifi).",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

enum StatusType { dot, icon }

class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final StatusType type;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.type = StatusType.icon,
    this.onTap,
  });

  factory StatusChip.sleeping({VoidCallback? onTap}) {
    return StatusChip(
      label: 'Sleeping',
      backgroundColor: AppColors.sleepBg,
      textColor: AppColors.sleepText,
      type: StatusType.dot,
      onTap: onTap,
    );
  }

  factory StatusChip.healthy() {
    return const StatusChip(
      label: 'Healthy',
      icon: Icons.shield_outlined,
      backgroundColor: AppColors.healthBg,
      textColor: AppColors.healthText,
      type: StatusType.icon,
    );
  }

  factory StatusChip.connected() {
    return const StatusChip(
      label: 'Connected',
      icon: Icons.wifi,
      backgroundColor: AppColors.connectBg,
      textColor: AppColors.connectText,
      type: StatusType.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == StatusType.dot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                color: textColor,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}`
  },
  {
    name: "live_camera_card.dart",
    path: "lib/features/dashboard/presentation/widgets/live_camera_card.dart",
    language: "dart",
    description: "Mock camera monitor utilizing custom canvas stars, multi-state camera controls, and high-contrast night vision layers.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class LiveCameraCard extends StatelessWidget {
  const LiveCameraCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C1B4D),
                    Color(0xFF1E112C),
                  ],
                ),
              ),
              child: Opacity(
                opacity: 0.45,
                child: Image.network(
                  'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.child_care,
                        color: Colors.white.withOpacity(0.2),
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: StarsPainter(),
            ),
          ),
          Positioned(
            left: 14,
            top: 45,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarMiniButton(Icons.videocam_rounded, 'Cameras'),
                _buildSidebarMiniButton(Icons.lightbulb_rounded, 'Lights'),
                _buildSidebarMiniButton(Icons.thermostat_rounded, 'Temp & Air'),
                _buildSidebarMiniButton(Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 45,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSidebarStatusText('LULLABY', 'On', Icons.volume_up_rounded),
                _buildSidebarStatusText('NIGHT LIGHT', 'On', Icons.nights_stay_rounded),
                _buildSidebarStatusText('AUDIO', 'High', Icons.mic_rounded),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Home Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'TUE, OCT 26   11:47 PM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Camera Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.nights_stay,
              color: Colors.white.withOpacity(0.4),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMiniButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white.withOpacity(0.85),
        size: 14,
      ),
    );
  }

  Widget _buildSidebarStatusText(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 10),
          const SizedBox(width: 4),
          Text(
            '\$title \$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 1, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), 1.5, paint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.75), 1, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 1.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}`
  },
  {
    name: "summary_card.dart",
    path: "lib/features/dashboard/presentation/widgets/summary_card.dart",
    language: "dart",
    description: "Displays rich biometric data using custom rounded shadows and fluid layout sizing.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.metricValue,
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: unit,
                    style: AppTypography.metricUnit,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}`
  },
  {
    name: "ai_insight_card.dart",
    path: "lib/features/dashboard/presentation/widgets/ai_insight_card.dart",
    language: "dart",
    description: "An AI-branded notification panel rendering pediatric and sleep recommendations with loading states.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class AIInsightCard extends StatelessWidget {
  final String insight;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AIInsightCard({
    super.key,
    required this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDFA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Insight',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onRefresh != null)
                      GestureDetector(
                        onTap: isLoading ? null : onRefresh,
                        child: AnimatedRotation(
                          turns: isLoading ? 1 : 0,
                          duration: const Duration(seconds: 1),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Color(0xFFEBE3FC),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    insight,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}`
  },
  {
    name: "quick_action_button.dart",
    path: "lib/features/dashboard/presentation/widgets/quick_action_button.dart",
    language: "dart",
    description: "Standard action tab providing clean feedback animations and structured layout parameters.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}`
  },
  {
    name: "bottom_navigation.dart",
    path: "lib/features/dashboard/presentation/widgets/bottom_navigation.dart",
    language: "dart",
    description: "Displays the active tab inside a highlighted capsule pill matching the Maatriva visual signature.",
    content: `import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.videocam_outlined, 'Live'),
            _buildNavItem(2, Icons.favorite_rounded, 'Health'),
            _buildNavItem(3, Icons.shopping_bag_outlined, 'Shop'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}`
  }
];

export const CodeExplorer: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<FlutterFile>(flutterFilesList[1]); // default to main.dart
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="flex flex-col h-full bg-white border border-indigo-50 rounded-[24px] overflow-hidden shadow-sm">
      {/* Explorer Header */}
      <div className="flex items-center justify-between px-6 py-4 bg-slate-50 border-b border-indigo-50">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-indigo-50 text-indigo-600">
            <Layers className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-sm font-semibold text-indigo-950">Flutter Architecture Explorer</h2>
            <p className="text-xs text-slate-500">Clean architecture, decoupled widgets & Riverpod state</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[10px] bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-full font-mono font-bold border border-emerald-100">
            FLUTTER 3.35+
          </span>
          <span className="text-[10px] bg-indigo-50 text-indigo-700 px-2.5 py-1 rounded-full font-mono font-bold border border-indigo-100">
            SOLID
          </span>
        </div>
      </div>

      {/* Main split */}
      <div className="flex flex-1 min-h-0 divide-x divide-indigo-50">
        {/* Sidebar file tree */}
        <div className="w-64 flex-shrink-0 bg-slate-50/40 overflow-y-auto p-4">
          <div className="mb-4">
            <div className="flex items-center gap-2 px-2 py-1.5 text-xs font-bold text-slate-400 uppercase tracking-wider">
              <Folder className="w-3.5 h-3.5" /> Project Structure
            </div>
            
            {/* Pubspec & Main */}
            <div className="space-y-1 mt-2">
              {flutterFilesList.slice(0, 3).map((file) => (
                <button
                  key={file.path}
                  onClick={() => setSelectedFile(file)}
                  className={`w-full flex items-center gap-2 px-3 py-2 text-xs rounded-lg transition-colors text-left ${
                    selectedFile.path === file.path
                      ? "bg-indigo-50 text-indigo-700 font-semibold border-l-4 border-indigo-600 pl-2 rounded-l-none"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-950"
                  }`}
                >
                  <FileCode className="w-3.5 h-3.5 flex-shrink-0" />
                  <span className="truncate">{file.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Theme Folder */}
          <div className="mb-4">
            <div className="flex items-center gap-2 px-2 py-1.5 text-xs font-bold text-slate-400 uppercase tracking-wider">
              <Folder className="w-3.5 h-3.5" /> theme/
            </div>
            <div className="space-y-1 mt-1 pl-2 border-l border-indigo-50 ml-3">
              {flutterFilesList.slice(3, 6).map((file) => (
                <button
                  key={file.path}
                  onClick={() => setSelectedFile(file)}
                  className={`w-full flex items-center gap-2 px-3 py-1.5 text-xs rounded-lg transition-colors text-left ${
                    selectedFile.path === file.path
                      ? "bg-indigo-50 text-indigo-700 font-semibold border-l-4 border-indigo-600 pl-2 rounded-l-none"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-950"
                  }`}
                >
                  <FileCode className="w-3.5 h-3.5 flex-shrink-0" />
                  <span className="truncate">{file.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Widgets Folder */}
          <div>
            <div className="flex items-center gap-2 px-2 py-1.5 text-xs font-bold text-slate-400 uppercase tracking-wider">
              <Folder className="w-3.5 h-3.5" /> dashboard/
            </div>
            <div className="space-y-1 mt-1 pl-2 border-l border-indigo-50 ml-3">
              <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-widest px-2 py-1">presentation/</div>
              
              {/* Providers & Screens */}
              {flutterFilesList.slice(6, 10).map((file) => (
                <button
                  key={file.path}
                  onClick={() => setSelectedFile(file)}
                  className={`w-full flex items-center gap-2 px-3 py-1.5 text-xs rounded-lg transition-colors text-left ${
                    selectedFile.path === file.path
                      ? "bg-indigo-50 text-indigo-700 font-semibold border-l-4 border-indigo-600 pl-2 rounded-l-none"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-950"
                  }`}
                >
                  <FileCode className="w-3.5 h-3.5 flex-shrink-0" />
                  <span className="truncate">{file.name}</span>
                </button>
              ))}

              <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-widest px-2 py-1 mt-2">widgets/</div>
              {/* Reusable Widgets */}
              {flutterFilesList.slice(10).map((file) => (
                <button
                  key={file.path}
                  onClick={() => setSelectedFile(file)}
                  className={`w-full flex items-center gap-2 px-3 py-1.5 text-xs rounded-lg transition-colors text-left ${
                    selectedFile.path === file.path
                      ? "bg-indigo-50 text-indigo-700 font-semibold border-l-4 border-indigo-600 pl-2 rounded-l-none"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-950"
                  }`}
                >
                  <FileCode className="w-3.5 h-3.5 flex-shrink-0" />
                  <span className="truncate">{file.name}</span>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Code view and metadata panel */}
        <div className="flex flex-col flex-1 min-w-0 bg-slate-950">
          {/* File description & metadata */}
          <div className="px-6 py-4 bg-slate-900 border-b border-slate-800">
            <div className="flex items-center justify-between">
              <span className="text-xs font-mono text-indigo-400">{selectedFile.path}</span>
              <button
                onClick={handleCopy}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg transition-colors cursor-pointer"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                {copied ? "Copied!" : "Copy Code"}
              </button>
            </div>
            <p className="text-xs text-slate-300 mt-2 font-sans italic bg-slate-950/50 p-2.5 rounded-lg border border-slate-800/60">
              <strong className="text-indigo-400 not-italic font-semibold">Architect's Note:</strong> {selectedFile.description}
            </p>
          </div>

          {/* Actual Code Area */}
          <div className="flex-1 overflow-auto p-6 font-mono text-xs text-slate-300 select-all leading-relaxed whitespace-pre bg-[#0d0e15] border-t border-[#1b1c28]">
            {selectedFile.content}
          </div>
        </div>
      </div>
    </div>
  );
};
