import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../../provider/health_reports_provider.dart';
import '../widgets/health_header.dart';
import '../widgets/report_filter_tabs.dart';
import '../widgets/health_score_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/report_history_card.dart';

class HealthReportsScreen extends ConsumerStatefulWidget {
  const HealthReportsScreen({super.key});

  @override
  ConsumerState<HealthReportsScreen> createState() =>
      _HealthReportsScreenState();
}

class _HealthReportsScreenState extends ConsumerState<HealthReportsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(healthReportsProvider);
    final report = reportState.currentReport;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HealthHeader(),
      body: reportState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Tabs
                  const ReportFilterTabs(),

                  // Health Score Card
                  HealthScoreCard(
                    score: report.score,
                    status: report.status,
                    summary: report.aiSummary,
                  ),

                  const SizedBox(height: 16),

                  // Health Metrics Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Row 1: Body Temp & Heart Rate
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 165,
                                child: MetricCard(
                                  label: report.metrics[0].label,
                                  value: report.metrics[0].value,
                                  unit: report.metrics[0].unit,
                                  icon: report.metrics[0].icon,
                                  changeText: report.metrics[0].changeText,
                                  iconBgColor: report.metrics[0].iconBgColor,
                                  iconColor: report.metrics[0].iconColor,
                                  trendIcon: report.metrics[0].trendIcon,
                                  trendColor: report.metrics[0].trendColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 165,
                                child: MetricCard(
                                  label: report.metrics[1].label,
                                  value: report.metrics[1].value,
                                  unit: report.metrics[1].unit,
                                  icon: report.metrics[1].icon,
                                  changeText: report.metrics[1].changeText,
                                  iconBgColor: report.metrics[1].iconBgColor,
                                  iconColor: report.metrics[1].iconColor,
                                  trendIcon: report.metrics[1].trendIcon,
                                  trendColor: report.metrics[1].trendColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: Room Temp (Single 50% Card or Expanded next to Spacer)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 165,
                                child: MetricCard(
                                  label: report.metrics[2].label,
                                  value: report.metrics[2].value,
                                  unit: report.metrics[2].unit,
                                  icon: report.metrics[2].icon,
                                  changeText: report.metrics[2].changeText,
                                  iconBgColor: report.metrics[2].iconBgColor,
                                  iconColor: report.metrics[2].iconColor,
                                  trendIcon: report.metrics[2].trendIcon,
                                  trendColor: report.metrics[2].trendColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: SizedBox(height: 165),
                            ), // Maintain balanced design grid layout
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sleep Duration (Full Width linear bar indicator)
                        SleepProgressCard(
                          label: report.metrics[3].label,
                          value: report.metrics[3].value,
                          changeText: report.metrics[3].changeText,
                          icon: report.metrics[3].icon,
                          iconBgColor: report.metrics[3].iconBgColor,
                          iconColor: report.metrics[3].iconColor,
                          badgeText:
                              report.metrics[3].badgeText ?? 'GOOD QUALITY',
                          badgeBgColor:
                              report.metrics[3].badgeColor ??
                              const Color(0xFFE8F5E9),
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Motion Activity & Baby Position
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 165,
                                child: MetricCard(
                                  label: report.metrics[4].label,
                                  value: report.metrics[4].value,
                                  unit: report.metrics[4].unit,
                                  icon: report.metrics[4].icon,
                                  changeText: report.metrics[4].changeText,
                                  iconBgColor: report.metrics[4].iconBgColor,
                                  iconColor: report.metrics[4].iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 165,
                                child: BabyPositionCard(
                                  label: report.metrics[5].label,
                                  value: report.metrics[5].value,
                                  changeText: report.metrics[5].changeText,
                                  icon: report.metrics[5].icon,
                                  iconBgColor: report.metrics[5].iconBgColor,
                                  iconColor: report.metrics[5].iconColor,
                                  badgeText:
                                      report.metrics[5].badgeText ?? 'SAFE',
                                  badgeBgColor:
                                      report.metrics[5].badgeColor ??
                                      const Color(0xFFE8F5E9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // AI Health Insights Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'AI Health Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI Insights Cards List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: report.insights.map((insight) {
                        return InsightCard(
                          text: insight.text,
                          icon: insight.icon,
                          iconColor: insight.iconColor,
                          bgColor: insight.bgColor,
                        );
                      }).toList(),
                    ),
                  ),

                  // Health Alerts Section (Only display if alerts exist)
                  if (report.alerts.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Health Alerts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: report.alerts.map((alert) {
                          return AlertCard(
                            title: alert.title,
                            timeText: alert.timeText,
                            icon: alert.icon,
                            color: alert.color,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Daily Timeline Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Daily Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TimelineWidget(events: report.timeline),
                  ),

                  const SizedBox(height: 16),

                  // Report History Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Report History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Opening archive of past medical reports...',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: report.history.map((historyItem) {
                        return ReportHistoryCard(
                          score: historyItem.score,
                          date: historyItem.date,
                          summary: historyItem.summary,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

      // Soft Glow Floating Action Button to Generate a New Report (simulates active query)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          onPressed: () {
            // Re-trigger current filter state to simulate beautiful loader updates
            ref
                .read(healthReportsProvider.notifier)
                .changeFilter(reportState.selectedFilter);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Analyzing new telemetry and updating scorecard...',
                ),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),

      // Integrated Bottom Navigation Bar matching user requirements
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // Keeps home or corresponding highlighted state
        onTap: (index) {
          context.go('/');
        },
      ),
    );
  }
}
