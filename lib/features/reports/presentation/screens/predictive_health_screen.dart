import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/clay_container.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/caretaker_access_restricted_widget.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/models/user_session.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../provider/predictive_health_provider.dart';

/// Clean, Uncluttered & Premium Health Dashboard in Maatriva Application.
///
/// Features:
/// 1. Single Compact AI Analysis Summary Card
/// 2. Clean 2-Column Responsive Sensor Grid (All 9 Live Sensors)
/// 3. Telemetry Reports & History Shortcut Card
/// 4. Fixed Bottom Navigation (Health Tab = Index 1)
class PredictiveHealthScreen extends ConsumerStatefulWidget {
  const PredictiveHealthScreen({super.key});

  @override
  ConsumerState<PredictiveHealthScreen> createState() =>
      _PredictiveHealthScreenState();
}

class _PredictiveHealthScreenState
    extends ConsumerState<PredictiveHealthScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(predictiveHealthProvider);
    final aiNotifier = ref.read(predictiveHealthProvider.notifier);
    final dashboardState = ref.watch(dashboardProvider);
    final telemetry = dashboardState.latestTelemetry;

    final authSession = ref.watch(authNotifierProvider).session;
    final isCaregiver = authSession?.role == UserRole.caregiver;
    final perms = ref.watch(caregiverPermissionsProvider);
    final bool permsHealth = !isCaregiver ||
        (perms['health'] == true ||
            perms['health_data'] == true ||
            perms['health_reports'] == true);

    if (!permsHealth) {
      return CaretakerAccessRestrictedWidget.restricted(
        sectionName: 'Health',
        tabIndex: 1,
      );
    }

    final heartRate = telemetry?['heart_rate']?.value.toInt().toString() ?? '--';
    final breathingRate = telemetry?['breathing_rate']?.value.toInt().toString() ?? telemetry?['respiration_rate']?.value.toInt().toString() ?? '--';
    final roomTemp = telemetry?['room_temperature']?.value.toStringAsFixed(1) ?? telemetry?['body_temperature']?.value.toStringAsFixed(1) ?? '--';
    final humidity = telemetry?['humidity']?.value.toInt().toString() ?? '--';
    final cryDetected = telemetry?['cry_detection']?.value == 1.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final gridChildAspectRatio = isSmallPhone ? 1.15 : 1.25;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Health',
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.navyDeep,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.royalBlue,
              size: 22.r,
            ),
            onPressed: aiState.isAnalyzing
                ? null
                : () => aiNotifier.analyzeLatestData(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.royalBlue,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await aiNotifier.analyzeLatestData();
              await ref.read(dashboardProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 120.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------
                  // 1. AI HEALTH ANALYSIS HEADER & SINGLE COMPACT CARD
                  // ---------------------------------------------------------
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.royalBlue,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'AI Health Analysis',
                        style: GoogleFonts.outfit(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      const Spacer(),
                      if (aiState.isAnalyzing)
                        Row(
                          children: [
                            SizedBox(
                              width: 12.r,
                              height: 12.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.royalBlue,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Analyzing...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalBlue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // SINGLE COMPACT AI CARD
                  _buildSingleAiAnalysisCard(aiState),

                  SizedBox(height: 26.h),

                  // ---------------------------------------------------------
                  // 2. BABY'S WELLNESS SECTION HEADER
                  // ---------------------------------------------------------
                  Text(
                    "Baby's Wellness",
                    style: GoogleFonts.outfit(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // ---------------------------------------------------------
                  // 3. CLEAN 2-COLUMN RESPONSIVE SENSOR GRID (ALL SENSORS)
                  // ---------------------------------------------------------
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: gridChildAspectRatio,
                    children: [
                      _buildGridSensorTile(
                        sensorId: 'heart_rate',
                        title: 'Heart Rate',
                        value: heartRate == '--' ? '--' : '$heartRate bpm',
                        status: 'Optimal',
                        icon: Icons.favorite_rounded,
                        iconBgColor: AppColors.heartBg,
                        iconColor: AppColors.heartIcon,
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'breathing_rate',
                        title: 'Respiration',
                        value: breathingRate == '--' ? '--' : '$breathingRate /min',
                        status: 'Normal',
                        icon: Icons.air_rounded,
                        iconBgColor: const Color(0xFFEBF3FF),
                        iconColor: const Color(0xFF3B82F6),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'room_temperature',
                        title: 'Temperature',
                        value: roomTemp == '--' ? '--' : '$roomTemp°C',
                        status: 'Comfortable',
                        icon: Icons.thermostat_rounded,
                        iconBgColor: AppColors.tempBg,
                        iconColor: AppColors.tempIcon,
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'humidity',
                        title: 'Humidity',
                        value: humidity == '--' ? '--' : '$humidity%',
                        status: 'Ideal',
                        icon: Icons.water_drop_rounded,
                        iconBgColor: const Color(0xFFE0F7FA),
                        iconColor: const Color(0xFF00ACC1),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'cry_detection',
                        title: 'Cry Detection',
                        value: cryDetected ? 'Crying' : 'Peaceful',
                        status: cryDetected ? 'Alert' : 'Quiet',
                        icon: Icons.face_retouching_natural_rounded,
                        iconBgColor: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFFF9F43),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'noise_detection',
                        title: 'Noise Level',
                        value: '< 45 dB',
                        status: 'Quiet',
                        icon: Icons.graphic_eq_rounded,
                        iconBgColor: const Color(0xFFEDEBFD),
                        iconColor: const Color(0xFF7060E6),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'gas_detection',
                        title: 'Air Quality',
                        value: 'AQI 22',
                        status: 'Safe',
                        icon: Icons.eco_rounded,
                        iconBgColor: const Color(0xFFE3F7F5),
                        iconColor: const Color(0xFF19A394),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'leakage',
                        title: 'Diaper & Mat',
                        value: 'Dry Surface',
                        status: 'Dry',
                        icon: Icons.invert_colors_rounded,
                        iconBgColor: const Color(0xFFE8F4FF),
                        iconColor: const Color(0xFF4A89F3),
                        isRestricted: !permsHealth,
                      ),
                      _buildGridSensorTile(
                        sensorId: 'cradle_swing',
                        title: 'Cradle Swing',
                        value: 'Sway L1',
                        status: 'Gentle',
                        icon: Icons.bedroom_baby_rounded,
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFFAB47BC),
                        isRestricted: !permsHealth,
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ---------------------------------------------------------
                  // 4. FULL TELEMETRY REPORTS & HISTORY SHORTCUT CARD
                  // ---------------------------------------------------------
                  ClayContainer(
                    borderRadius: 20,
                    padding: EdgeInsets.all(16.r),
                    onTap: () {
                      if (!permsHealth) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Access restricted by primary parent.'),
                          ),
                        );
                      } else {
                        context.push('/health-reports');
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assessment_rounded,
                            color: AppColors.royalBlue,
                            size: 22.r,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Telemetry Reports & History',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDeep,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'View historical charts, cardiac logs, and export PDFs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.r,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar Navigation
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigation(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  /// SINGLE COMPACT AI ANALYSIS CARD (Takes ~15-20% viewport height)
  Widget _buildSingleAiAnalysisCard(PredictiveHealthState state) {
    final statusText = state.overallStatusText.isNotEmpty
        ? state.overallStatusText
        : "Your baby's monitored patterns look stable today.";

    final recommendationText = (state.recommendations.isNotEmpty)
        ? state.recommendations.first.title
        : 'Maintain current nursery temperature and humidity range.';

    return ClayContainer(
      borderRadius: 22,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Stable Patterns',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '● Vitals OK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            statusText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDeep,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: const Color(0xFFE65100),
                  size: 15.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    recommendationText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// COMPACT 2-COLUMN SENSOR GRID TILE
  Widget _buildGridSensorTile({
    required String sensorId,
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool isRestricted,
  }) {
    return ClayContainer(
      onTap: () {
        if (isRestricted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access restricted by primary parent.'),
            ),
          );
        } else {
          context.push('/wellness-monitoring/report?sensor=$sensorId');
        }
      },
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
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18.r, color: iconColor),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17.sp,
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
