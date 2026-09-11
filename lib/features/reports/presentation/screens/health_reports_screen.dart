import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import 'package:maatriva/shared/widgets/caretaker_access_restricted_widget.dart';
import '../../provider/health_reports_provider.dart';
import '../../../../shared/models/health_report.dart';
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

  HealthMetric _findMetric(List<HealthMetric> metrics, String label, {
    required IconData defaultIcon,
    required Color defaultColor,
    required Color defaultBgColor,
  }) {
    try {
      return metrics.firstWhere(
        (m) => m.label.toLowerCase() == label.toLowerCase(),
      );
    } catch (_) {
      return HealthMetric(
        label: label,
        value: '--',
        unit: '',
        icon: defaultIcon,
        changeText: 'No data',
        iconBgColor: defaultBgColor,
        iconColor: defaultColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final reportState = ref.watch(healthReportsProvider);
    final report = reportState.currentReport;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HealthHeader(),
      body: _buildBody(reportState, report),
      // Soft Glow Floating Action Button to Generate a New Report
      floatingActionButton: reportState.isLoading || reportState.hasInsufficientData
          ? null
          : Container(
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
                  ref.read(healthReportsProvider.notifier).loadReport();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Analyzing telemetry and regenerating report...',
                      ),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 0,
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
              ),
            ),
      // Integrated Bottom Navigation Bar matching user requirements
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildBody(HealthReportsState reportState, HealthReport? report) {
    if (reportState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (reportState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 16),
              Text(
                reportState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(healthReportsProvider.notifier).loadReport();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (reportState.hasInsufficientData || report == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const ReportFilterTabs(),
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EDFA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Not enough data yet. Continue monitoring to receive insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Biometric telemetry logs are collected periodically from the smart cradle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(healthReportsProvider.notifier).loadReport();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Check Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Safely extract metrics
    final bodyTemp = _findMetric(
      report.metrics,
      'Body Temp',
      defaultIcon: Icons.thermostat_outlined,
      defaultColor: const Color(0xFFFF9800),
      defaultBgColor: const Color(0xFFFFF3CD),
    );
    final heartRate = _findMetric(
      report.metrics,
      'Heart Rate',
      defaultIcon: Icons.favorite_border_rounded,
      defaultColor: const Color(0xFF8855EC),
      defaultBgColor: const Color(0xFFF3EDFA),
    );
    final roomTemp = _findMetric(
      report.metrics,
      'Room Temp',
      defaultIcon: Icons.home_outlined,
      defaultColor: const Color(0xFF2196F3),
      defaultBgColor: const Color(0xFFE3F2FD),
    );
    final sleepDuration = _findMetric(
      report.metrics,
      'Sleep Duration',
      defaultIcon: Icons.nights_stay_outlined,
      defaultColor: const Color(0xFF673AB7),
      defaultBgColor: const Color(0xFFEDE7F6),
    );
    final motionActivity = _findMetric(
      report.metrics,
      'Motion Activity',
      defaultIcon: Icons.waves_rounded,
      defaultColor: const Color(0xFF4CAF50),
      defaultBgColor: const Color(0xFFE8F5E9),
    );
    final babyPosition = _findMetric(
      report.metrics,
      'Baby Position',
      defaultIcon: Icons.airline_seat_flat_rounded,
      defaultColor: const Color(0xFF8855EC),
      defaultBgColor: const Color(0xFFF3EDFA),
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(healthReportsProvider.notifier).loadReport(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
                            label: bodyTemp.label,
                            value: bodyTemp.value,
                            unit: bodyTemp.unit,
                            icon: bodyTemp.icon,
                            changeText: bodyTemp.changeText,
                            iconBgColor: bodyTemp.iconBgColor,
                            iconColor: bodyTemp.iconColor,
                            trendIcon: bodyTemp.trendIcon,
                            trendColor: bodyTemp.trendColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 165,
                          child: MetricCard(
                            label: heartRate.label,
                            value: heartRate.value,
                            unit: heartRate.unit,
                            icon: heartRate.icon,
                            changeText: heartRate.changeText,
                            iconBgColor: heartRate.iconBgColor,
                            iconColor: heartRate.iconColor,
                            trendIcon: heartRate.trendIcon,
                            trendColor: heartRate.trendColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Room Temp
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 165,
                          child: MetricCard(
                            label: roomTemp.label,
                            value: roomTemp.value,
                            unit: roomTemp.unit,
                            icon: roomTemp.icon,
                            changeText: roomTemp.changeText,
                            iconBgColor: roomTemp.iconBgColor,
                            iconColor: roomTemp.iconColor,
                            trendIcon: roomTemp.trendIcon,
                            trendColor: roomTemp.trendColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: SizedBox(height: 165),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sleep Duration
                  SleepProgressCard(
                    label: sleepDuration.label,
                    value: sleepDuration.value,
                    changeText: sleepDuration.changeText,
                    icon: sleepDuration.icon,
                    iconBgColor: sleepDuration.iconBgColor,
                    iconColor: sleepDuration.iconColor,
                    badgeText: sleepDuration.badgeText ?? 'GOOD QUALITY',
                    badgeBgColor: sleepDuration.badgeColor ?? const Color(0xFFE8F5E9),
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Motion Activity & Baby Position
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 165,
                          child: MetricCard(
                            label: motionActivity.label,
                            value: motionActivity.value,
                            unit: motionActivity.unit,
                            icon: motionActivity.icon,
                            changeText: motionActivity.changeText,
                            iconBgColor: motionActivity.iconBgColor,
                            iconColor: motionActivity.iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 165,
                          child: BabyPositionCard(
                            label: babyPosition.label,
                            value: babyPosition.value,
                            changeText: babyPosition.changeText,
                            icon: babyPosition.icon,
                            iconBgColor: babyPosition.iconBgColor,
                            iconColor: babyPosition.iconColor,
                            badgeText: babyPosition.badgeText ?? 'SAFE',
                            badgeBgColor: babyPosition.badgeColor ?? const Color(0xFFE8F5E9),
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

            // Health Alerts Section
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

            // Timeline Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Timeline',
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
    );
  }
}
