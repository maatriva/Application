import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../provider/predictive_health_provider.dart';

/// Modal Bottom Sheet that presents detailed telemetry insights, sparkline trend graphs,
/// clear pediatric-friendly explanations (What noticed, Why it matters, What to do),
/// and medical disclaimers.
class InsightDetailSheet extends StatefulWidget {
  final PredictiveRiskInsight insight;

  const InsightDetailSheet({
    super.key,
    required this.insight,
  });

  static void show(BuildContext context, PredictiveRiskInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsightDetailSheet(insight: insight),
    );
  }

  @override
  State<InsightDetailSheet> createState() => _InsightDetailSheetState();
}

class _InsightDetailSheetState extends State<InsightDetailSheet> {
  int _selectedPeriodIndex = 0; // 0 = 24h, 1 = 7 Days, 2 = 30 Days

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B70).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Header: Category Title + Risk Level Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: insight.riskLevel.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          insight.icon,
                          color: insight.riskLevel.color,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF183B70),
                            ),
                          ),
                          Text(
                            'AI Monitored Pattern',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: insight.riskLevel.bgColor,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: insight.riskLevel.color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: insight.riskLevel.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          insight.riskLevel.badgeTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: insight.riskLevel.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Summary banner card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  insight.summary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Trend Chart Section
              Text(
                'Pattern Trend Graph',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF183B70),
                ),
              ),
              SizedBox(height: 10.h),

              // Period Toggle Filter Tabs
              Row(
                children: ['Last 24 Hours', 'Last 7 Days', 'Last 30 Days'].asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = _selectedPeriodIndex == idx;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPeriodIndex = idx;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6E3DE0) : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 14.h),

              // Line Chart Display
              Container(
                height: 140.h,
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12.w, 16.h, 16.w, 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF183B70).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      show: false,
                    ),
                    borderData: FlBorderData(show: false),
                    minY: insight.sparklineData.isNotEmpty
                        ? insight.sparklineData.reduce((a, b) => a < b ? a : b) - 2
                        : 0,
                    maxY: insight.sparklineData.isNotEmpty
                        ? insight.sparklineData.reduce((a, b) => a > b ? a : b) + 2
                        : 50,
                    lineBarsData: [
                      LineChartBarData(
                        spots: insight.sparklineData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: insight.riskLevel.color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: insight.riskLevel.color.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // AI EXPLANATION TRIO (What noticed, Why matters, What you can do)
              Text(
                'AI Pattern Breakdown',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF183B70),
                ),
              ),
              SizedBox(height: 10.h),

              _buildExplanationCard(
                icon: Icons.search_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                title: 'WHAT DID MAATRIVA NOTICE?',
                content: insight.whatNoticed,
              ),
              SizedBox(height: 10.h),

              _buildExplanationCard(
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                title: 'WHY DOES IT MATTER?',
                content: insight.whyItMatters,
              ),
              SizedBox(height: 10.h),

              _buildExplanationCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFD1FAE5),
                title: 'WHAT CAN YOU DO?',
                content: insight.whatYouCanDo,
              ),
              SizedBox(height: 20.h),

              // Relevant Telemetry Signals list
              Text(
                'Contributing Telemetry Signals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF183B70),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: insight.relevantSignals.map((signal) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded, size: 14.r, color: const Color(0xFF6E3DE0)),
                        SizedBox(width: 6.w),
                        Text(
                          signal,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),

              // Safety Disclaimer
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: const Color(0xFF64748B),
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'AI-generated insight — not a medical diagnosis. Always consult a qualified pediatrician for health concerns.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E3DE0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B70).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
