import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';

import '../../../../shared/widgets/bottom_navigation.dart';
import '../../provider/predictive_health_provider.dart';
import '../widgets/baby_cloud_mascot.dart';
import '../widgets/insight_detail_sheet.dart';

/// Redesigned Predictive Health Screen in Maatriva Flutter Application.
///
/// Strictly enforces the "Safe & Secure" claymorphic design language:
/// - Unified pale aqua/mint card surface (`#EAF8F7` / `AppColors.predictiveCardBg`) across ALL cards
/// - Pale cyan canvas background (`#DFF3F4`) to create high depth and contrast
/// - Soft 26px rounded corners, subtle white highlight, soft clay depth shadows
/// - Status colors reserved strictly for badges, icons, borders, and text accents
/// - Larger, spacious, touch-friendly cards with clear visual hierarchy
/// - Preserves 100% of underlying backend data streams, Riverpod state, and AI logic
class PredictiveHealthScreen extends ConsumerStatefulWidget {
  const PredictiveHealthScreen({super.key});

  @override
  ConsumerState<PredictiveHealthScreen> createState() =>
      _PredictiveHealthScreenState();
}

class _PredictiveHealthScreenState
    extends ConsumerState<PredictiveHealthScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isTransparencyExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Unified Claymorphic Card Container Builder.
  /// Guarantees that ALL cards on this page share the exact same pale aqua/mint
  /// surface, corner radius, soft depth shadows, and border treatment.
  Widget _buildClayCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 26.0,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    final cardWidget = Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.predictiveCardBg, // Soft pale aqua/mint #EAF8F7
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: AppColors.predictiveClayShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictiveHealthProvider);
    final notifier = ref.read(predictiveHealthProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.predictiveCanvasBg, // Soft pale cyan #DFF3F4
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(74.h),
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
                      icon: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.predictiveCardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF173A70).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: const Color(0xFF173A70),
                          size: 20.r,
                        ),
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Predictive Health',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF173A70),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'AI-powered insights from monitored patterns',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.predictiveCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF173A70).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                  ),
                  onPressed: state.isAnalyzing ? null : () => notifier.analyzeLatestData(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.predictiveCardBg,
            onRefresh: () async {
              await notifier.analyzeLatestData();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 130.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. AI Analysis Status Pill Banner
                  _buildAiStatusHeader(state),
                  SizedBox(height: 20.h),

                  if (state.isLoading) ...[
                    _buildLoadingShimmer(),
                  ] else if (state.errorMessage != null && state.riskInsights.isEmpty) ...[
                    _buildErrorView(state.errorMessage!, notifier),
                  ] else if (state.isInsufficientData) ...[
                    _buildInsufficientDataView(),
                  ] else ...[
                    // 2. Hero Section: Overall Health Insight Card + Mascot
                    _buildHeroSection(state),
                    SizedBox(height: 24.h),

                    // 3. AI Risk Insights Section
                    _buildRiskInsightsSection(state),
                    SizedBox(height: 28.h),

                    // 4. Monitoring Factors Section
                    _buildMonitoringFactorsSection(state),
                    SizedBox(height: 28.h),

                    // 5. AI Pattern Insights Section
                    _buildPatternInsightsSection(state),
                    SizedBox(height: 28.h),

                    // 6. AI Recommendations Section
                    _buildRecommendationsSection(state),
                    SizedBox(height: 28.h),

                    // 7. AI Transparency & Safety Disclaimer
                    _buildTransparencySection(state),
                  ],
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

  /// 1. AI Status Indicator Pill Header
  Widget _buildAiStatusHeader(PredictiveHealthState state) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.predictiveCardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173A70).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isAnalyzing) ...[
                SizedBox(
                  width: 14.r,
                  height: 14.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '✨ Analyzing latest patterns...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 15.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  '✨ AI Analysis Updated',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14.r,
              color: const Color(0xFF64748B),
            ),
            SizedBox(width: 4.w),
            Text(
              state.lastAnalysisTimeStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. Hero Section: Overall Health Insight Card + Baby Mascot
  Widget _buildHeroSection(PredictiveHealthState state) {
    return _buildClayCard(
      padding: EdgeInsets.all(22.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Info Side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFC1C8),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: const Color(0xFFEE5265),
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Overall Health Insight',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF173A70),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    Text(
                      state.overallStatusText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF173A70),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              // Right Baby Mascot Illustration
              const BabyCloudMascot(width: 110, height: 100),
            ],
          ),
          SizedBox(height: 16.h),

          // Status Badges Row (Low Risk / Stable, Trend: Stable, Today)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              // Risk Level Pill Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: state.overallLevel.bgColor,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: state.overallLevel.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: state.overallLevel.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      state.overallLevel == RiskLevel.stable
                          ? 'Low Risk'
                          : state.overallLevel.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: state.overallLevel.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Pattern Trend Pill Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: const Color(0xFF81C784).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: const Color(0xFF2E7D32),
                      size: 14.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Stable Pattern',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

              // Timestamp Pill Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.today_rounded,
                      color: const Color(0xFF64748B),
                      size: 14.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. AI Risk Insights Section (Cards with unified #EAF8F7 surface)
  Widget _buildRiskInsightsSection(PredictiveHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Risk Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF173A70),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '${state.riskInsights.length} Patterns Monitored',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        SizedBox(
          height: 220.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: state.riskInsights.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final item = state.riskInsights[index];
              return _buildRiskInsightCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRiskInsightCard(BuildContext context, PredictiveRiskInsight item) {
    return _buildClayCard(
      width: 250.w,
      height: 220.h,
      padding: EdgeInsets.all(18.r),
      onTap: () => InsightDetailSheet.show(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Soft rounded icon container
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: item.riskLevel.bgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: item.riskLevel.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: item.riskLevel.color,
                  size: 20.r,
                ),
              ),

              // Status badge pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: item.riskLevel.bgColor,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: item.riskLevel.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  item.riskLevel.badgeTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: item.riskLevel.color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Text(
            item.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
          SizedBox(height: 4.h),

          Text(
            item.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          SizedBox(height: 8.h),

          Row(
            children: [
              Text(
                'View Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15.r,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Monitoring Factors Section (Spacious 2-column grid inside unified #EAF8F7 card)
  Widget _buildMonitoringFactorsSection(PredictiveHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'Monitoring Factors',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        _buildClayCard(
          padding: EdgeInsets.all(18.r),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.85,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: state.monitoringFactors.length,
            itemBuilder: (context, index) {
              final factor = state.monitoringFactors[index];
              return Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF173A70).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.r),
                      decoration: BoxDecoration(
                        color: factor.bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        factor.icon,
                        color: factor.iconColor,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            factor.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            factor.valueText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF173A70),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: factor.statusLevel.bgColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              factor.statusTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: factor.statusLevel.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 5. AI Pattern Insights Section
  Widget _buildPatternInsightsSection(PredictiveHealthState state) {
    if (state.patternInsights.isEmpty) return const SizedBox.shrink();

    final item = state.patternInsights.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'AI Pattern Insights',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        _buildClayCard(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF173A70),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFFD8B4FE),
                      ),
                    ),
                    child: Text(
                      'Observed: ${item.observedPeriod}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              Text(
                item.summaryText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: const Color(0xFF334155),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                'Contributing factors:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 8.h),

              ...item.contributingFactors.map((factor) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    children: [
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          factor,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// 6. AI Recommendations Section (Horizontal/Vertical Cards with unified #EAF8F7 surface)
  Widget _buildRecommendationsSection(PredictiveHealthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            'AI Recommendations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        ...state.recommendations.map((rec) {
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _buildClayCard(
              padding: EdgeInsets.all(18.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: rec.bgColor,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: rec.iconColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      rec.icon,
                      color: rec.iconColor,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: rec.iconColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          rec.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF173A70),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          rec.explanation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 7. AI Transparency & Safety Medical Disclaimer Section
  Widget _buildTransparencySection(PredictiveHealthState state) {
    return _buildClayCard(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isTransparencyExpanded = !_isTransparencyExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'How does Maatriva analyze this?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF173A70),
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isTransparencyExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
          if (_isTransparencyExpanded) ...[
            SizedBox(height: 12.h),
            Text(
              'Maatriva continuously evaluates sensor telemetry, ambient nursery environment metrics, and historical baseline trends to present supportive wellness insights for parents.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
          SizedBox(height: 16.h),

          // Mandatory Medical Disclaimer Box
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: const Color(0xFF64748B),
                  size: 20.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'AI-generated insights are not a medical diagnosis. Consult a qualified healthcare professional for medical concerns.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  /// Shimmer / Spinner Loading State View inside unified Clay Card
  Widget _buildLoadingShimmer() {
    return _buildClayCard(
      padding: EdgeInsets.all(28.r),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 18.h),
          Text(
            '✨ Analyzing your baby\'s recent patterns...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Processing real-time sensor streams and nursery ambient signals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  /// Insufficient Data State View inside unified Clay Card
  Widget _buildInsufficientDataView() {
    return _buildClayCard(
      padding: EdgeInsets.all(28.r),
      child: Column(
        children: [
          Icon(Icons.query_stats_rounded, size: 52.r, color: const Color(0xFF94A3B8)),
          SizedBox(height: 14.h),
          Text(
            'Not Enough Data Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Continue monitoring and Maatriva will provide AI insights once enough telemetry data has been collected.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5.sp,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Error State View inside unified Clay Card
  Widget _buildErrorView(String message, PredictiveHealthNotifier notifier) {
    return _buildClayCard(
      padding: EdgeInsets.all(28.r),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 48.r, color: const Color(0xFFEA580C)),
          SizedBox(height: 14.h),
          Text(
            'AI Analysis Temporarily Unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF173A70),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Live monitoring is still active.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => notifier.fetchAnalysisData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
