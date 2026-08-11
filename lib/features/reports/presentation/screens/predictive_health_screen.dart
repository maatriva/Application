import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../../provider/predictive_health_provider.dart';

class PredictiveHealthScreen extends ConsumerStatefulWidget {
  const PredictiveHealthScreen({super.key});

  @override
  ConsumerState<PredictiveHealthScreen> createState() =>
      _PredictiveHealthScreenState();
}

class _PredictiveHealthScreenState
    extends ConsumerState<PredictiveHealthScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPatternsExpanded = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictiveHealthProvider);
    final notifier = ref.read(predictiveHealthProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FD),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: const Color(0xFF6E3DE0),
                        size: 24.r,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    SizedBox(width: 4.w),
                    CircleAvatar(
                      radius: 18.r,
                      backgroundImage: const NetworkImage(
                        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120",
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Predictive',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6E3DE0),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Health',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6E3DE0),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        color: AppColors.textSecondary,
                        size: 22.r,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Sharing report with pediatricians...",
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 22.r,
                      ),
                      onPressed: () {
                        context.push('/profile');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 140.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. System Stability Index Card
                _buildStabilityIndexCard(state, notifier),
                SizedBox(height: 20.h),

                // 2. Vitals Indicators Row
                _buildVitalsRow(state),
                SizedBox(height: 24.h),

                // 3. Potential Chronic Patterns Expandable Section
                _buildChronicPatternsSection(state),
                SizedBox(height: 24.h),

                // 4. Correlation Trends Section (30 Days)
                _buildCorrelationTrendsSection(state),
                SizedBox(height: 24.h),

                // 5. Preventive Recommendations Section
                _buildRecommendationsSection(state),
              ],
            ),
          ),

          // Sticky Consult Doctor & Bottom Bar Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Consult Doctor Button (Sticky above the bottom nav)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Initiating call with Pediatrician...",
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF3B82F6),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FA0FF),
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_in_talk_rounded, size: 18.r),
                          SizedBox(width: 8.w),
                          Text(
                            "Consult Doctor",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Expanded Bottom Navigation
                const BottomNavigation(currentIndex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD 1: SYSTEM STABILITY INDEX
  // =========================================================================
  Widget _buildStabilityIndexCard(
    PredictiveHealthState state,
    PredictiveHealthNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(22.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDFA),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "AI Diagnostic Insight",
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8855EC),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "System Stability\nIndex",
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              // Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64.r,
                    height: 64.r,
                    child: CircularProgressIndicator(
                      value: state.stabilityIndex / 100.0,
                      strokeWidth: 6.r,
                      backgroundColor: const Color(0xFFF1EEFA),
                      color: const Color(0xFF6E3DE0),
                    ),
                  ),
                  Text(
                    "${state.stabilityIndex}",
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6E3DE0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            state.diagnosticInsight,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: state.isAnalyzing
                ? null
                : () => notifier.runAIAnalysis(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E3DE0),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
              elevation: 0,
            ),
            child: state.isAnalyzing
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        "Generate Full AI Analysis",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 2: VITALS INDICATORS ROW
  // =========================================================================
  Widget _buildVitalsRow(PredictiveHealthState state) {
    return Row(
      children: state.vitals.map((vital) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(vital.icon, color: vital.color, size: 14.r),
                    SizedBox(width: 4.w),
                    Text(
                      vital.name,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  vital.status,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: vital.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // SECTION 3: POTENTIAL CHRONIC PATTERNS
  // =========================================================================
  Widget _buildChronicPatternsSection(PredictiveHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isPatternsExpanded = !_isPatternsExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Potential Chronic Patterns",
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(
                _isPatternsExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF6E3DE0),
                size: 20.r,
              ),
            ],
          ),
        ),
        if (_isPatternsExpanded) ...[
          SizedBox(height: 12.h),
          Column(
            children: state.chronicPatterns.map((pattern) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            color: pattern.iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            pattern.icon,
                            color: pattern.iconColor,
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pattern.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                pattern.description,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${pattern.probability}%",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            Text(
                              "Prob.",
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDFA).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            color: const Color(0xFF8855EC),
                            size: 14.r,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              pattern.evidence,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8855EC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // SECTION 4: CORRELATION TRENDS (30 DAYS)
  // =========================================================================
  Widget _buildCorrelationTrendsSection(PredictiveHealthState state) {
    // Render side-by-side vertical bars for a custom bar chart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Correlation Trends (30 Days)",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            children: [
              // Custom Bar Chart Representation
              SizedBox(
                height: 140.h,
                child: Stack(
                  children: [
                    // Grid Lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return Container(
                          height: 1.h,
                          color: const Color(0xFFF3EEFA).withOpacity(0.6),
                        );
                      }),
                    ),
                    // Bars
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: state.trendData.map((dataPoint) {
                          // Standardized heights based on values
                          final hrPercent =
                              (dataPoint.heartRate - 100) /
                              30.0; // 0.0 to 1.0 range
                          final tempPercent =
                              (dataPoint.temperature - 36.0) /
                              1.5; // 0.0 to 1.0 range

                          final hrHeight =
                              40.h + (hrPercent * 80.h).clamp(0.0, 90.h);
                          final tempHeight =
                              30.h + (tempPercent * 90.h).clamp(0.0, 90.h);

                          return SizedBox(
                            height: 140.h,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Heart Rate Bar (Purple)
                                Container(
                                  width: 8.w,
                                  height: hrHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC0A4FA),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                // Temp Bar (Blue)
                                Container(
                                  width: 8.w,
                                  height: tempHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007DFE),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC0A4FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Heart Rate",
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 24.w),
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007DFE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Body Temp",
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SECTION 5: PREVENTIVE RECOMMENDATIONS
  // =========================================================================
  Widget _buildRecommendationsSection(PredictiveHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Preventive Recommendations",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Column(
          children: state.recommendations.map((rec) {
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDFA),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(rec.icon, color: rec.iconColor, size: 16.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      rec.text,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
