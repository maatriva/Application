import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/models/user_session.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/caretaker_access_restricted_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/models/ai_feature_model.dart';
import '../../providers/ai_subscription_provider.dart';
import 'ai_monitoring_screen.dart';

class AiSubscriptionScreen extends ConsumerWidget {
  const AiSubscriptionScreen({super.key});

  static const List<AiFeatureModel> _featuresList = [
    // High Priority
    AiFeatureModel(
      id: 'posture_detection',
      name: 'Posture Detection',
      description: 'Real-time infant sleeping posture & roll-over safety monitoring.',
      icon: Icons.child_care_rounded,
      emoji: '🧑‍🍼',
      status: 'Normal',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.high,
      category: 'Safety & Motion',
      analysis: 'Baby is sleeping safely on back.',
      detailedInsight: 'Computer vision camera tracks baby body axis to alert parents if baby rolls onto stomach.',
      metrics: {'Posture': 'On Back', 'Safety': 'Optimal'},
    ),
    AiFeatureModel(
      id: 'cry_analysis',
      name: 'Cry Analysis',
      description: 'Acoustic spectral classification of crying patterns & discomfort levels.',
      icon: Icons.record_voice_over_rounded,
      emoji: '😭',
      status: 'Low Concern',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.high,
      category: 'Acoustics',
      analysis: 'No pain or fatigue cry patterns detected.',
      detailedInsight: 'AI audio analyzer categorizes infant cries into hunger, fatigue, diaper discomfort, or pain.',
      metrics: {'Cry Index': '0.0', 'Frequency': 'Quiet'},
    ),
    // Medium Priority
    AiFeatureModel(
      id: 'movement_monitoring',
      name: 'Movement Monitoring',
      description: 'Micro-motion tracking of arm & leg restlessness during sleep.',
      icon: Icons.directions_run_rounded,
      emoji: '🚶',
      status: 'Normal',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.medium,
      category: 'Activity',
      analysis: 'Restlessness is minimal.',
      detailedInsight: 'Radar and video movement sensors monitor nocturnal motor activity and startle reflexes.',
      metrics: {'Motion Level': '12%', 'Rest Index': 'High'},
    ),
    AiFeatureModel(
      id: 'sleep_analysis',
      name: 'Sleep Analysis',
      description: 'Sleep cycle stage segmentation & deep sleep efficiency metrics.',
      icon: Icons.nights_stay_rounded,
      emoji: '😴',
      status: 'Good',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.medium,
      category: 'Sleep',
      analysis: 'Deep sleep ratio is 89%.',
      detailedInsight: 'Tracks circadian sleep quality, REM stages, light sleep, and sleep interruption counts.',
      metrics: {'Duration': '8h 24m', 'Efficiency': '89%'},
    ),
    AiFeatureModel(
      id: 'facial_state_analysis',
      name: 'Facial State Analysis',
      description: 'Landmark camera analysis for infant emotional distress & comfort.',
      icon: Icons.face_rounded,
      emoji: '😟',
      status: 'Calm',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.medium,
      category: 'Vision',
      analysis: 'Facial muscle tone is relaxed.',
      detailedInsight: 'Detects eye closure, forehead tension, and smile landmarks during wakefulness and sleep.',
      metrics: {'Expression': 'Calm', 'Tension': 'Low'},
    ),
    AiFeatureModel(
      id: 'heart_rate_detection',
      name: 'Heart Rate Detection',
      description: 'Optical sensor pulse analysis & abnormal rhythm detection.',
      icon: Icons.favorite_rounded,
      emoji: '❤️',
      status: 'Stable',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.medium,
      category: 'Vitals',
      analysis: 'Heart rate is 124 bpm (normal infant range).',
      detailedInsight: 'Monitors cardiac rate and heart rate variability (HRV) for early illness detection.',
      metrics: {'BPM': '124', 'Rhythm': 'Regular'},
    ),
    AiFeatureModel(
      id: 'respiratory_rate_detection',
      name: 'Respiratory Rate Detection',
      description: 'Chest-expansion respiratory tracking & breath frequency.',
      icon: Icons.air_rounded,
      emoji: '🫁',
      status: 'Stable',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.medium,
      category: 'Vitals',
      analysis: 'Breathing rate is 34 rpm.',
      detailedInsight: 'Uses micro-radar to monitor chest rise and fall, detecting apnea pauses or shallow breathing.',
      metrics: {'RPM': '34', 'Airway': 'Clear'},
    ),
    // Low Priority
    AiFeatureModel(
      id: 'sentiment_engine',
      name: 'Sentiment / Behavioral Engine',
      description: 'Long-term emotional balance & environmental mood tracking.',
      icon: Icons.mood_rounded,
      emoji: '🙂',
      status: 'Content',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.low,
      category: 'Behavior',
      analysis: 'Positive mood stability score.',
      detailedInsight: 'Synthesizes diurnal crying, sleep, and interaction events to estimate nursery contentment.',
      metrics: {'Mood': 'Content', 'Score': '9.4/10'},
    ),
    AiFeatureModel(
      id: 'gases_analysis',
      name: 'Gases Analysis',
      description: 'Air quality, VOC & CO2 toxic gas safety monitoring.',
      icon: Icons.co2_rounded,
      emoji: '😷',
      status: 'Fresh Air',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.low,
      category: 'Environment',
      analysis: 'Air quality is excellent (412 ppm CO2).',
      detailedInsight: 'IoT sensor continuously checks VOCs, carbon dioxide, ambient temperature, and humidity.',
      metrics: {'CO2': '412 ppm', 'Air Quality': 'Clean'},
    ),
    AiFeatureModel(
      id: 'voice_assistant',
      name: 'Voice Assistant',
      description: 'Interactive AI pediatrician voice agent & automatic lullaby soothing.',
      icon: Icons.smart_toy_rounded,
      emoji: '🤖',
      status: 'Ready',
      statusColor: Color(0xFF2E7D32),
      priority: AiFeaturePriority.low,
      category: 'AI Agent',
      analysis: 'Interactive pediatrician agent standby.',
      detailedInsight: 'Conversational AI agent capable of answering pediatric queries and playing soothing lullabies.',
      metrics: {'Status': 'Ready', 'Agent': 'Online'},
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authNotifierProvider).session;
    final isCaregiver = authSession?.role == UserRole.caregiver;

    if (isCaregiver) {
      final perms = ref.watch(caregiverPermissionsProvider);
      final bool hasAiPerm = perms['ai_monitoring'] == true ||
          perms['ai'] == true ||
          perms['canViewAiMonitoring'] == true;

      if (hasAiPerm) {
        return const AiMonitoringScreen();
      }

      return CaretakerAccessRestrictedWidget.restricted(
        sectionName: 'AI Monitoring',
        tabIndex: 2,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Maatriva AI',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.navyDeep,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDeep),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Header Banner Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF), Color(0xFF5478E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha:0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha:0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Maatriva AI',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smart AI-powered monitoring for your little one.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha:0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Annual Price Display Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: AppColors.royalBlue.withValues(alpha:0.12), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'UNLIMITED ANNUAL ACCESS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹10,000',
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navyDeep,
                          ),
                        ),
                        Text(
                          ' / year',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Billed annually • Full 10 AI Monitoring Modules',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary CTA Unlock Button
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(aiSubscriptionProvider.notifier).unlockSubscription();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Maatriva AI Unlocked Successfully! (Simulated)'),
                              backgroundColor: Color(0xFF2E7D32),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/ai-monitoring');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock Maatriva AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Developer Simulation Note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            'Local development mode — payment is simulated.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB78103),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. AI Modules Title
              Text(
                'Includes 10 AI Monitoring Capabilities',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Feature Cards List (High, Medium, Low Priority Sections)
              ..._buildPrioritySection('HIGH PRIORITY MODULES', AiFeaturePriority.high),
              const SizedBox(height: 16),
              ..._buildPrioritySection('MEDIUM PRIORITY MODULES', AiFeaturePriority.medium),
              const SizedBox(height: 16),
              ..._buildPrioritySection('LOW PRIORITY MODULES', AiFeaturePriority.low),

              const SizedBox(height: 32),

              // Bottom Lock CTA Repeat
              ElevatedButton(
                onPressed: () async {
                  await ref.read(aiSubscriptionProvider.notifier).unlockSubscription();
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/ai-monitoring');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Unlock Maatriva AI — ₹10,000 / year',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }

  List<Widget> _buildPrioritySection(String sectionTitle, AiFeaturePriority priority) {
    final list = _featuresList.where((f) => f.priority == priority).toList();

    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          sectionTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: priority == AiFeaturePriority.high
                ? const Color(0xFFE53935)
                : (priority == AiFeaturePriority.medium ? const Color(0xFFFB8C00) : AppColors.royalBlue),
            letterSpacing: 1.0,
          ),
        ),
      ),
      ...list.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
            border: Border.all(color: const Color(0xFFE4F0F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    feature.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feature.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDeep,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: feature.priorityColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature.priorityLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: feature.priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }
}
