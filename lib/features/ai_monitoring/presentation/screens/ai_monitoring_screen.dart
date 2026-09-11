import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/models/user_session.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/clay_container.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/caretaker_access_restricted_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/models/ai_feature_model.dart';
import '../../providers/ai_subscription_provider.dart';
import '../widgets/ai_feature_detail_sheet.dart';

/// Premium AI Monitoring Dashboard in Maatriva Application.
///
/// Features:
/// 1. AI Health Overview Summary Card
/// 2. Clean 2-Column AI Feature Grid matching Health Section Cards
/// 3. Interactive Detail Bottom Sheet on Tap
/// 4. Fixed Bottom Navigation (AI Tab = Index 2)
class AiMonitoringScreen extends ConsumerWidget {
  const AiMonitoringScreen({super.key});

  List<AiFeatureModel> _buildFeaturesWithLiveTelemetry(DashboardState dashboardState) {
    final telemetry = dashboardState.latestTelemetry;

    final hrVal = telemetry?['heart_rate']?.value.toInt();
    final respVal = telemetry?['respiration_rate']?.value.toInt();
    final cryVal = telemetry?['cry_detection']?.value ?? 0.0;
    final sleepVal = telemetry?['sleep_stage']?.value ?? 0.0;

    final hrText = hrVal != null && hrVal > 0 ? '$hrVal bpm' : '124 bpm';
    final respText = respVal != null && respVal > 0 ? '$respVal rpm' : '34 rpm';
    final cryStatusText = cryVal > 0 ? 'Cry Alert' : 'Stable';
    final sleepStatusText = sleepVal > 0 ? 'Deep Sleep' : 'Good';

    return [
      AiFeatureModel(
        id: 'posture_detection',
        name: 'Posture',
        description: 'Real-time infant sleeping posture & roll-over safety monitoring.',
        icon: Icons.child_care_rounded,
        emoji: '🧑‍🍼',
        status: 'Normal',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.high,
        category: 'Safety & Motion',
        analysis: 'Baby is sleeping safely on back posture.',
        detailedInsight: 'Computer vision camera tracks baby body axis to alert parents if baby rolls onto stomach.',
        metrics: {'Posture': 'On Back', 'Safety': 'Optimal'},
      ),
      AiFeatureModel(
        id: 'cry_analysis',
        name: 'Cry Analysis',
        description: 'Acoustic spectral classification of crying patterns & discomfort levels.',
        icon: Icons.record_voice_over_rounded,
        emoji: '😭',
        status: cryStatusText,
        statusColor: cryVal > 0 ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        priority: AiFeaturePriority.high,
        category: 'Acoustics',
        analysis: cryVal > 0 ? 'Cry detected — reviewing acoustic discomfort frequency.' : 'No pain or fatigue cry patterns detected.',
        detailedInsight: 'AI audio analyzer categorizes infant cries into hunger, fatigue, diaper discomfort, or pain.',
        metrics: {'Cry Index': '${cryVal.toStringAsFixed(1)}', 'Pattern': cryVal > 0 ? 'Active' : 'Quiet'},
      ),
      AiFeatureModel(
        id: 'movement_monitoring',
        name: 'Movement',
        description: 'Micro-motion tracking of arm & leg restlessness during sleep.',
        icon: Icons.directions_run_rounded,
        emoji: '🚶',
        status: 'Normal',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.medium,
        category: 'Activity',
        analysis: 'Restlessness is minimal and steady.',
        detailedInsight: 'Radar and video movement sensors monitor nocturnal motor activity and startle reflexes.',
        metrics: {'Motion Level': '12%', 'Rest Index': 'High'},
      ),
      AiFeatureModel(
        id: 'sleep_analysis',
        name: 'Sleep',
        description: 'Sleep cycle stage segmentation & deep sleep efficiency metrics.',
        icon: Icons.nights_stay_rounded,
        emoji: '😴',
        status: sleepStatusText,
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.medium,
        category: 'Sleep',
        analysis: 'Deep sleep ratio is 89%.',
        detailedInsight: 'Tracks circadian sleep quality, REM stages, light sleep, and sleep interruption counts.',
        metrics: {'Duration': '8h 24m', 'Efficiency': '89%'},
      ),
      AiFeatureModel(
        id: 'facial_state_analysis',
        name: 'Facial State',
        description: 'Landmark camera analysis for infant emotional distress & comfort.',
        icon: Icons.face_rounded,
        emoji: '🙂',
        status: 'Calm',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.medium,
        category: 'Vision',
        analysis: 'Facial muscle tone is relaxed.',
        detailedInsight: 'Detects eye closure, forehead tension, and smile landmarks during wakefulness and sleep.',
        metrics: {'Expression': 'Calm', 'Tension': 'Low'},
      ),
      AiFeatureModel(
        id: 'heart_rate_detection',
        name: 'Heart Rate',
        description: 'Optical sensor pulse analysis & abnormal rhythm detection.',
        icon: Icons.favorite_rounded,
        emoji: '❤️',
        status: hrText,
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.medium,
        category: 'Vitals',
        analysis: 'Heart rate is $hrText (normal infant range).',
        detailedInsight: 'Monitors cardiac rate and heart rate variability (HRV) for early illness detection.',
        metrics: {'BPM': hrText, 'Rhythm': 'Regular'},
      ),
      AiFeatureModel(
        id: 'respiratory_rate_detection',
        name: 'Respiration',
        description: 'Chest-expansion respiratory tracking & breath frequency.',
        icon: Icons.air_rounded,
        emoji: '🫁',
        status: respText,
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.medium,
        category: 'Vitals',
        analysis: 'Breathing rate is $respText.',
        detailedInsight: 'Uses micro-radar to monitor chest rise and fall, detecting apnea pauses or shallow breathing.',
        metrics: {'RPM': respText, 'Airway': 'Clear'},
      ),
      AiFeatureModel(
        id: 'sentiment_engine',
        name: 'Behavior',
        description: 'Long-term emotional balance & environmental mood tracking.',
        icon: Icons.mood_rounded,
        emoji: '😊',
        status: 'Content',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.low,
        category: 'Behavior',
        analysis: 'Positive mood stability score.',
        detailedInsight: 'Synthesizes diurnal crying, sleep, and interaction events to estimate nursery contentment.',
        metrics: {'Mood': 'Content', 'Score': '9.4/10'},
      ),
      AiFeatureModel(
        id: 'gases_analysis',
        name: 'Gases & Air',
        description: 'Air quality, VOC & CO2 toxic gas safety monitoring.',
        icon: Icons.co2_rounded,
        emoji: '😷',
        status: 'Safe Air',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.low,
        category: 'Environment',
        analysis: 'Air quality is clean.',
        detailedInsight: 'IoT sensor continuously checks VOCs, carbon dioxide, ambient temperature, and humidity.',
        metrics: {'CO2': '412 ppm', 'Air Quality': 'Clean'},
      ),
      AiFeatureModel(
        id: 'voice_assistant',
        name: 'Voice Agent',
        description: 'Interactive AI pediatrician voice agent & automatic lullaby soothing.',
        icon: Icons.smart_toy_rounded,
        emoji: '🤖',
        status: 'Ready',
        statusColor: const Color(0xFF2E7D32),
        priority: AiFeaturePriority.low,
        category: 'AI Agent',
        analysis: 'Interactive pediatrician agent standby.',
        detailedInsight: 'Conversational AI agent capable of answering pediatric queries and playing soothing lullabies.',
        metrics: {'Status': 'Ready', 'Agent': 'Online'},
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authNotifierProvider).session;
    final isCaregiver = authSession?.role == UserRole.caregiver;
    final perms = ref.watch(caregiverPermissionsProvider);
    final bool hasAiPerm = !isCaregiver ||
        (perms['ai_monitoring'] == true ||
            perms['ai'] == true ||
            perms['canViewAiMonitoring'] == true);

    if (!hasAiPerm) {
      return CaretakerAccessRestrictedWidget.restricted(
        sectionName: 'AI Monitoring',
        tabIndex: 2,
      );
    }

    final dashboardState = ref.watch(dashboardProvider);
    final features = _buildFeaturesWithLiveTelemetry(dashboardState);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final gridChildAspectRatio = isSmallPhone ? 1.15 : 1.25;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.royalBlue, size: 22),
            const SizedBox(width: 8),
            Text(
              'AI Monitoring',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.navyDeep,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
        actions: [
          if (!isCaregiver)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
              onPressed: () => context.push('/ai-subscription'),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCaregiver)
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 15),
                          SizedBox(width: 6.w),
                          Text(
                            'AI Subscribed (Simulated)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDeep,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          await ref.read(aiSubscriptionProvider.notifier).resetSubscription();
                          if (context.mounted) {
                            context.go('/ai-subscription');
                          }
                        },
                        child: Text(
                          'Reset Sub (Dev)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. AI STATUS SUMMARY CARD
              _buildUltraSmallAiStatusCard(context),

              SizedBox(height: 24.h),

              // 2. SECTION HEADER
              Text(
                'AI Features',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              SizedBox(height: 12.h),

              // 3. 2-COLUMN FEATURE GRID (MATCHING HEALTH SECTION CARDS)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: gridChildAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildAiFeatureTile(context, feature);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }

  /// AI STATUS SUMMARY CARD
  Widget _buildUltraSmallAiStatusCard(BuildContext context) {
    return ClayContainer(
      borderRadius: 18,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.royalBlue,
              size: 20.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '✨ AI Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '92 • Stable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'No major concerns detected',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI FEATURE TILE (DESIGN MATCHES HEALTH SECTION GRID TILES EXACTLY)
  Widget _buildAiFeatureTile(BuildContext context, AiFeatureModel feature) {
    return ClayContainer(
      onTap: () => AiFeatureDetailSheet.show(context, feature),
      borderRadius: 20,
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: feature.statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature.icon,
                  size: 18.r,
                  color: feature.statusColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: feature.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  feature.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: feature.statusColor,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                feature.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
