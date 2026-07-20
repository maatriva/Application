import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/health_report_data.dart';

enum ReportFilter { today, yesterday, last7Days }

class HealthReportsState {
  final ReportFilter selectedFilter;
  final bool isLoading;
  final HealthReport currentReport;

  HealthReportsState({
    required this.selectedFilter,
    required this.isLoading,
    required this.currentReport,
  });

  HealthReportsState copyWith({
    ReportFilter? selectedFilter,
    bool? isLoading,
    HealthReport? currentReport,
  }) {
    return HealthReportsState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      currentReport: currentReport ?? this.currentReport,
    );
  }
}

class HealthReportsNotifier extends StateNotifier<HealthReportsState> {
  HealthReportsNotifier()
    : super(
        HealthReportsState(
          selectedFilter: ReportFilter.today,
          isLoading: false,
          currentReport: _getReportForFilter(ReportFilter.today),
        ),
      );

  void changeFilter(ReportFilter filter) {
    state = state.copyWith(isLoading: true, selectedFilter: filter);
    // Simulate minor loading transition for card animations to trigger beautifully
    Future.delayed(const Duration(milliseconds: 250), () {
      state = state.copyWith(
        isLoading: false,
        currentReport: _getReportForFilter(filter),
      );
    });
  }

  static HealthReport _getReportForFilter(ReportFilter filter) {
    switch (filter) {
      case ReportFilter.today:
        return HealthReport(
          score: 94,
          status: 'Excellent',
          aiSummary:
              'Mateo had a restful night with stable vitals. Room conditions were optimal for deep sleep cycles.',
          metrics: [
            HealthMetric(
              label: 'Body Temp',
              value: '36.5°C',
              unit: '',
              icon: Icons.thermostat_outlined,
              changeText: 'L: 36.2  H: 36.8',
              iconBgColor: const Color(0xFFFFF3CD),
              iconColor: const Color(0xFFFFC107),
              trendIcon: Icons.trending_flat_rounded,
              trendColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Heart Rate',
              value: '115 bpm',
              unit: '',
              icon: Icons.favorite_border_rounded,
              changeText: 'AVG: 112  MAX: 128',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              trendIcon: Icons.trending_up_rounded,
              trendColor: const Color(0xFF8855EC),
            ),
            HealthMetric(
              label: 'Room Temp',
              value: '22.4°C',
              unit: '',
              icon: Icons.ac_unit_outlined,
              changeText: 'OPT: 21.0  HIGH ALERT',
              iconBgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF2196F3),
              trendIcon: Icons.trending_up_rounded,
              trendColor: const Color(0xFFFF5722),
            ),
            HealthMetric(
              label: 'Sleep Duration',
              value: '8.2 hrs',
              unit: '',
              icon: Icons.nights_stay_outlined,
              changeText: '8.2 hrs of total rest',
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF673AB7),
              badgeText: '92% QUALITY',
              badgeColor: const Color(0xFFE8F5E9),
            ),
            HealthMetric(
              label: 'Motion Activity',
              value: '12 moves',
              unit: '',
              icon: Icons.waves_rounded,
              changeText: 'PREDOMINANTLY CALM',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Baby Position',
              value: 'Back',
              unit: '',
              icon: Icons.airline_seat_flat_rounded,
              changeText: '4 CHANGES TONIGHT',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              badgeText: 'SAFE',
              badgeColor: const Color(0xFFE8F5E9),
            ),
          ],
          insights: [
            HealthInsight(
              text: 'Baby slept peacefully for 7.5 hours.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF8855EC),
              bgColor: const Color(0xFFF6F2FD),
            ),
            HealthInsight(
              text: 'Body temperature remained stable.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF8855EC),
              bgColor: const Color(0xFFF6F2FD),
            ),
            HealthInsight(
              text: 'Minor movement increase at 2:30 AM.',
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF2196F3),
              bgColor: const Color(0xFFE3F2FD),
            ),
            HealthInsight(
              text: 'Safe sleeping posture maintained throughout.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF8855EC),
              bgColor: const Color(0xFFF6F2FD),
            ),
          ],
          alerts: [
            HealthAlert(
              title: 'High Room Temp',
              timeText: 'Resolved at 11:30 PM',
              severity: AlertSeverity.resolved,
              icon: Icons.thermostat_rounded,
              color: const Color(0xFFFF5722),
            ),
            HealthAlert(
              title: 'Safe Sleep Alert',
              timeText: 'Resolved at 03:00 AM',
              severity: AlertSeverity.resolved,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF4CAF50),
            ),
          ],
          timeline: [
            TimelineEvent(time: '08:00 AM', activity: 'Baby woke up'),
            TimelineEvent(time: '04:20 PM', activity: 'Sleep ended'),
            TimelineEvent(
              time: '01:45 PM',
              activity: 'Position changed to right',
            ),
            TimelineEvent(time: '11:30 AM', activity: 'Deep sleep started'),
          ],
          history: [
            ReportHistoryItem(
              score: 91,
              date: 'October 24, 2023',
              summary: '8.5h Sleep • Stable Temp',
            ),
            ReportHistoryItem(
              score: 88,
              date: 'October 23, 2023',
              summary: '7.9h Sleep • Minor Alerts',
            ),
          ],
        );
      case ReportFilter.yesterday:
        return HealthReport(
          score: 89,
          status: 'Good',
          aiSummary:
              'Mateo was slightly restless during the early hours of yesterday. Vitals remained stable, but room temp rose slightly above average around midnight.',
          metrics: [
            HealthMetric(
              label: 'Body Temp',
              value: '36.8°C',
              unit: '',
              icon: Icons.thermostat_outlined,
              changeText: 'L: 36.4  H: 37.1',
              iconBgColor: const Color(0xFFFFF3CD),
              iconColor: const Color(0xFFFFC107),
              trendIcon: Icons.trending_up_rounded,
              trendColor: const Color(0xFFFF9800),
            ),
            HealthMetric(
              label: 'Heart Rate',
              value: '118 bpm',
              unit: '',
              icon: Icons.favorite_border_rounded,
              changeText: 'AVG: 115  MAX: 132',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              trendIcon: Icons.trending_up_rounded,
              trendColor: const Color(0xFF8855EC),
            ),
            HealthMetric(
              label: 'Room Temp',
              value: '23.8°C',
              unit: '',
              icon: Icons.ac_unit_outlined,
              changeText: 'OPT: 21.0  HIGH ALERT',
              iconBgColor: const Color(0xFFFFEBEE),
              iconColor: const Color(0xFFE53935),
              trendIcon: Icons.trending_up_rounded,
              trendColor: const Color(0xFFE53935),
            ),
            HealthMetric(
              label: 'Sleep Duration',
              value: '7.4 hrs',
              unit: '',
              icon: Icons.nights_stay_outlined,
              changeText: '7.4 hrs of total rest',
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF673AB7),
              badgeText: '81% QUALITY',
              badgeColor: const Color(0xFFFFF3E0),
            ),
            HealthMetric(
              label: 'Motion Activity',
              value: '24 moves',
              unit: '',
              icon: Icons.waves_rounded,
              changeText: 'MODERATELY RESTLESS',
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFF9800),
            ),
            HealthMetric(
              label: 'Baby Position',
              value: 'Side',
              unit: '',
              icon: Icons.airline_seat_flat_rounded,
              changeText: '8 CHANGES TONIGHT',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              badgeText: 'MONITOR',
              badgeColor: const Color(0xFFFFEBEE),
            ),
          ],
          insights: [
            HealthInsight(
              text:
                  'Increased tossing and turning between 12:00 AM and 2:00 AM.',
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFFFF9800),
              bgColor: const Color(0xFFFFF8E1),
            ),
            HealthInsight(
              text: 'Heart rate showed slight spikes during crying episodes.',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFE53935),
              bgColor: const Color(0xFFFFEBEE),
            ),
            HealthInsight(
              text: 'Room temperature was slightly warm, peaking at 24.2°C.',
              icon: Icons.thermostat_outlined,
              iconColor: const Color(0xFFFF9800),
              bgColor: const Color(0xFFFFF8E1),
            ),
          ],
          alerts: [
            HealthAlert(
              title: 'High Room Temp',
              timeText: 'Resolved at 01:15 AM',
              severity: AlertSeverity.resolved,
              icon: Icons.thermostat_rounded,
              color: const Color(0xFFFF5722),
            ),
          ],
          timeline: [
            TimelineEvent(time: '07:30 AM', activity: 'Baby woke up'),
            TimelineEvent(
              time: '12:15 AM',
              activity: 'Crying detected (gas discomfort)',
            ),
            TimelineEvent(time: '11:00 PM', activity: 'Deep sleep started'),
          ],
          history: [
            ReportHistoryItem(
              score: 91,
              date: 'October 24, 2023',
              summary: '8.5h Sleep • Stable Temp',
            ),
            ReportHistoryItem(
              score: 88,
              date: 'October 23, 2023',
              summary: '7.9h Sleep • Minor Alerts',
            ),
          ],
        );
      case ReportFilter.last7Days:
        return HealthReport(
          score: 92,
          status: 'Excellent',
          aiSummary:
              'Over the last 7 days, Mateos health index was highly consistent. Sleep average is improving, and temperature spikes have fully subsided.',
          metrics: [
            HealthMetric(
              label: 'Body Temp',
              value: '36.6°C',
              unit: 'avg',
              icon: Icons.thermostat_outlined,
              changeText: 'L: 36.1  H: 36.9',
              iconBgColor: const Color(0xFFFFF3CD),
              iconColor: const Color(0xFFFFC107),
              trendIcon: Icons.trending_flat_rounded,
              trendColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Heart Rate',
              value: '114 bpm',
              unit: 'avg',
              icon: Icons.favorite_border_rounded,
              changeText: 'AVG: 112  MAX: 126',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              trendIcon: Icons.trending_flat_rounded,
              trendColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Room Temp',
              value: '21.8°C',
              unit: 'avg',
              icon: Icons.ac_unit_outlined,
              changeText: 'OPT: 21.0  HIGH ALERT',
              iconBgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF2196F3),
              trendIcon: Icons.trending_down_rounded,
              trendColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Sleep Duration',
              value: '8.0 hrs',
              unit: 'avg',
              icon: Icons.nights_stay_outlined,
              changeText: '8.0 hrs average daily sleep',
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF673AB7),
              badgeText: '88% QUALITY',
              badgeColor: const Color(0xFFE8F5E9),
            ),
            HealthMetric(
              label: 'Motion Activity',
              value: '15 moves',
              unit: 'avg',
              icon: Icons.waves_rounded,
              changeText: 'GENERALLY CALM',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
            ),
            HealthMetric(
              label: 'Baby Position',
              value: 'Back (90%)',
              unit: '',
              icon: Icons.airline_seat_flat_rounded,
              changeText: 'SAFE POSTURE SECURED',
              iconBgColor: const Color(0xFFF3EDFA),
              iconColor: const Color(0xFF8855EC),
              badgeText: 'EXCELLENT',
              badgeColor: const Color(0xFFE8F5E9),
            ),
          ],
          insights: [
            HealthInsight(
              text: 'Sleep duration is up by 15% compared to last week.',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF4CAF50),
              bgColor: const Color(0xFFE8F5E9),
            ),
            HealthInsight(
              text: 'Temperature regulation shows healthy development.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF8855EC),
              bgColor: const Color(0xFFF6F2FD),
            ),
            HealthInsight(
              text:
                  'Perfect adherence to safe sleep position (Back) for 90% of nights.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF8855EC),
              bgColor: const Color(0xFFF6F2FD),
            ),
          ],
          alerts: [], // No active alerts this week
          timeline: [
            TimelineEvent(
              time: 'Mon-Sun',
              activity: 'Woke up average 07:45 AM',
            ),
            TimelineEvent(
              time: 'Mon-Sun',
              activity: 'Bedtime average 08:30 PM',
            ),
          ],
          history: [
            ReportHistoryItem(
              score: 91,
              date: 'October 24, 2023',
              summary: '8.5h Sleep • Stable Temp',
            ),
            ReportHistoryItem(
              score: 88,
              date: 'October 23, 2023',
              summary: '7.9h Sleep • Minor Alerts',
            ),
          ],
        );
    }
  }
}

final healthReportsProvider =
    StateNotifierProvider<HealthReportsNotifier, HealthReportsState>((ref) {
      return HealthReportsNotifier();
    });
