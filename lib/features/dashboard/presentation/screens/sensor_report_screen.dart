import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../providers/sensor_report_provider.dart';

class SensorReportScreen extends ConsumerWidget {
  final String sensor;

  const SensorReportScreen({
    super.key,
    required this.sensor,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatHHMM(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getSensorTitle() {
    switch (sensor) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'breathing_rate':
        return 'Breathing Rate / Respiration';
      case 'room_temperature':
        return 'Room Temperature';
      case 'humidity':
        return 'Humidity';
      case 'cry_detection':
        return 'Cry Detection';
      case 'noise_detection':
        return 'Noise Detection';
      case 'gas_detection':
        return 'Gas & Air Quality';
      case 'leakage':
        return 'Diaper & Mat Leakage';
      case 'cradle_swing':
        return 'Cradle Swing & Motion';
      default:
        return 'Sensor Detail Report';
    }
  }

  IconData _getSensorIcon() {
    switch (sensor) {
      case 'heart_rate':
        return Icons.favorite_rounded;
      case 'breathing_rate':
        return Icons.air_rounded;
      case 'room_temperature':
        return Icons.thermostat_rounded;
      case 'humidity':
        return Icons.water_drop_rounded;
      case 'cry_detection':
        return Icons.face_retouching_natural_rounded;
      case 'noise_detection':
        return Icons.graphic_eq_rounded;
      case 'gas_detection':
        return Icons.eco_rounded;
      case 'leakage':
        return Icons.invert_colors_rounded;
      case 'cradle_swing':
        return Icons.bedroom_baby_rounded;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sensorReportFamilyProvider(sensor));
    final notifier = ref.read(sensorReportFamilyProvider(sensor).notifier);

    final title = _getSensorTitle();
    final isContinuous = ['heart_rate', 'breathing_rate', 'room_temperature', 'humidity'].contains(sensor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: state.isLoading
          ? _buildLoadingSkeleton()
          : state.errorMessage != null && state.data == null
              ? _buildErrorState(state.errorMessage!, () => notifier.fetchReport())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card (Live Value + Status)
                      _buildHeaderCard(state.data, isContinuous),

                      const SizedBox(height: 20),

                      // Time Range Selector Tabs (1D, 2D, 7D, 1M)
                      _buildPeriodTabs(state.period, (p) => notifier.changePeriod(p)),

                      const SizedBox(height: 20),

                      if (isContinuous) ...[
                        // Trend Graph Card
                        _buildContinuousGraph(state.data),

                        const SizedBox(height: 20),

                        // Summary Statistics Card
                        _buildSummaryStatsCard(state.data),

                        const SizedBox(height: 20),

                        // Notable Changes Section
                        _buildNotableChangesSection(state.data),
                      ] else ...[
                        // Event Timeline for Non-Continuous Sensors
                        _buildEventTimelineSection(state.data),
                      ],
                    ],
                  ),
                ),

      bottomNavigationBar: const BottomNavigation(currentIndex: -1),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic>? data, bool isContinuous) {
    final unit = data?['unit'] ?? '';
    final currentValue = data?['currentValue']?.toString() ?? '--';
    final currentStatus = data?['currentStatus'] ?? data?['statusLabel'] ?? 'Within configured range';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.clayShadow,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(_getSensorIcon(), size: 28, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSensorTitle(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isContinuous ? '$currentValue $unit' : currentStatus,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isContinuous ? '🟢 $currentStatus' : '🟢 Live Monitoring Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF047857),
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

  Widget _buildPeriodTabs(String selectedPeriod, ValueChanged<String> onSelected) {
    final periods = [
      {'label': '1 Day', 'key': '1d'},
      {'label': '2 Days', 'key': '2d'},
      {'label': '7 Days', 'key': '7d'},
      {'label': '1 Month', 'key': '1m'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = selectedPeriod == p['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(p['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p['label']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContinuousGraph(Map<String, dynamic>? data) {
    final pointsList = data?['points'] as List? ?? [];
    if (pointsList.isEmpty) {
      return _buildEmptyState();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < pointsList.length; i++) {
      final val = (pointsList[i]['value'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    final values = spots.map((s) => s.y).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.clayShadow,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TREND GRAPH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Aggregated Readable View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (spots.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < pointsList.length) {
                          final tsStr = pointsList[idx]['timestamp'] as String;
                          final dt = DateTime.tryParse(tsStr);
                          if (dt != null) {
                            return Text(
                              _formatHHMM(dt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
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

  Widget _buildSummaryStatsCard(Map<String, dynamic>? data) {
    final stats = data?['stats'] as Map<String, dynamic>? ?? {};
    final avg = stats['average']?.toString() ?? '--';
    final min = stats['minimum']?.toString() ?? '--';
    final max = stats['maximum']?.toString() ?? '--';
    final stable = stats['stablePeriod']?.toString() ?? '--';
    final unit = data?['unit'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.clayShadow,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERIOD SUMMARY STATISTICS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatTile('Average', '$avg $unit', Icons.analytics_outlined)),
              Expanded(child: _buildStatTile('Minimum', '$min $unit', Icons.arrow_downward_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatTile('Maximum', '$max $unit', Icons.arrow_upward_rounded)),
              Expanded(child: _buildStatTile('Stable Period', stable, Icons.shield_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotableChangesSection(Map<String, dynamic>? data) {
    final changes = data?['notableChanges'] as List? ?? [];
    if (changes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.clayShadow,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTABLE CHANGES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...changes.map((item) {
            final ts = item['timestamp'] != null
                ? _formatTime(DateTime.parse(item['timestamp']))
                : 'Just now';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_toggle_off_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['message'] ?? 'Reading adjusted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$ts • ${item['valueChange'] ?? ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventTimelineSection(Map<String, dynamic>? data) {
    final events = data?['events'] as List? ?? [];
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.clayShadow,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVENT & ACTIVITY TIMELINE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...events.map((event) {
            final dtStr = event['timestamp'] as String?;
            final dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
            final timeFormatted = dt != null ? _formatTime(dt) : 'Today';
            final severity = event['severity'] as String? ?? 'info';
            final durationText = event['durationText'] as String?;

            Color badgeColor = const Color(0xFF047857);
            Color badgeBg = AppColors.softMint;
            if (severity == 'warning') {
              badgeColor = const Color(0xFFD97706);
              badgeBg = const Color(0xFFFEF3C7);
            } else if (severity == 'danger') {
              badgeColor = const Color(0xFFDC2626);
              badgeBg = const Color(0xFFFEE2E2);
            } else if (severity == 'info') {
              badgeColor = AppColors.primary;
              badgeBg = AppColors.primaryLight;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getSensorIcon(), size: 18, color: badgeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                event['title'] ?? 'Event Logged',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (durationText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    durationText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event['subtitle'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            timeFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.textMuted,
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
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading ${_getSensorTitle()} report...',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, size: 48, color: AppColors.primaryLight),
          const SizedBox(height: 12),
          Text(
            'No historical data yet',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Once Maatriva receives enough readings, your baby\'s trend will appear here.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE53935)),
            const SizedBox(height: 12),
            Text(
              'Unable to load this report.',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
