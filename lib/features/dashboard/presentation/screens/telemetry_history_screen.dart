import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/telemetry_record.dart';
import '../../../reports/provider/telemetry_history_provider.dart';
import '../providers/dashboard_provider.dart';

class TelemetryHistoryScreen extends ConsumerStatefulWidget {
  final String sensorType;

  const TelemetryHistoryScreen({super.key, required this.sensorType});

  @override
  ConsumerState<TelemetryHistoryScreen> createState() => _TelemetryHistoryScreenState();
}

class _TelemetryHistoryScreenState extends ConsumerState<TelemetryHistoryScreen> {
  double _zoomLevel = 1.0; // 1.0 to 3.0 zoom range

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final dashboardState = ref.read(dashboardProvider);
    final babyId = dashboardState.baby?.id;
    if (babyId != null) {
      ref.read(telemetryHistoryProvider.notifier).fetchHistory(babyId);
    }
  }

  String _getSensorName() {
    switch (widget.sensorType) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'breathing_rate':
        return 'Breathing Rate';
      case 'body_temperature':
        return 'Body Temp';
      case 'room_temperature':
        return 'Room Temp';
      case 'humidity':
        return 'Humidity';
      case 'air_quality':
        return 'Air Quality';
      case 'sleep_stage':
        return 'Sleep Stage';
      case 'cry_detection':
        return 'Cry Detection';
      case 'movement_detection':
        return 'Movement';
      case 'battery_level':
        return 'Battery Level';
      default:
        return 'Sensor Detail';
    }
  }

  String _getSensorUnit() {
    switch (widget.sensorType) {
      case 'heart_rate':
        return 'bpm';
      case 'breathing_rate':
        return 'rpm';
      case 'body_temperature':
      case 'room_temperature':
        return '°C';
      case 'humidity':
      case 'battery_level':
        return '%';
      case 'air_quality':
        return 'AQI';
      default:
        return '';
    }
  }

  IconData _getSensorIcon() {
    switch (widget.sensorType) {
      case 'heart_rate':
        return Icons.favorite_border_rounded;
      case 'breathing_rate':
        return Icons.air_rounded;
      case 'body_temperature':
        return Icons.thermostat_outlined;
      case 'room_temperature':
        return Icons.home_outlined;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'air_quality':
        return Icons.eco_outlined;
      case 'sleep_stage':
        return Icons.nights_stay_outlined;
      case 'cry_detection':
        return Icons.face_retouching_natural_outlined;
      case 'movement_detection':
        return Icons.directions_run_outlined;
      case 'battery_level':
        return Icons.battery_std_rounded;
      default:
        return Icons.insert_chart_outlined_rounded;
    }
  }

  Color _getSensorColor() {
    switch (widget.sensorType) {
      case 'heart_rate':
        return AppColors.heartIcon;
      case 'breathing_rate':
        return AppColors.connectText;
      case 'body_temperature':
        return AppColors.tempIcon;
      case 'room_temperature':
        return AppColors.healthText;
      case 'humidity':
        return AppColors.tempIcon;
      case 'air_quality':
        return AppColors.sleepText;
      default:
        return AppColors.primary;
    }
  }

  Color _getSensorBgColor() {
    switch (widget.sensorType) {
      case 'heart_rate':
        return AppColors.heartBg;
      case 'breathing_rate':
        return AppColors.connectBg;
      case 'body_temperature':
        return AppColors.tempBg;
      case 'room_temperature':
        return AppColors.healthBg;
      case 'humidity':
        return AppColors.tempBg;
      case 'air_quality':
        return AppColors.sleepBg;
      default:
        return AppColors.primaryLight;
    }
  }

  double? _getRecordValue(TelemetryRecord record) {
    switch (widget.sensorType) {
      case 'heart_rate':
        return record.heartRate;
      case 'breathing_rate':
        return record.breathingRate;
      case 'body_temperature':
        return record.bodyTemperature;
      case 'room_temperature':
        return record.roomTemperature;
      case 'humidity':
        return record.humidity;
      case 'air_quality':
        return record.airQuality;
      case 'sleep_stage':
        return record.sleepStage == 'awake' ? 4.0 : (record.sleepStage == 'light_sleep' ? 3.0 : (record.sleepStage == 'rem' ? 2.0 : 1.0));
      case 'cry_detection':
        return record.cryDetected == true ? 1.0 : 0.0;
      case 'movement_detection':
        return record.movementDetected == true ? 1.0 : 0.0;
      case 'battery_level':
        return record.batteryLevel?.toDouble();
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  void _showCustomRangePicker(String babyId) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      ref.read(telemetryHistoryProvider.notifier).changeRange(
            babyId,
            HistoryTimeRange.custom,
            customFrom: pickedRange.start,
            customTo: pickedRange.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(telemetryHistoryProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final baby = dashboardState.baby;

    if (baby == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(_getSensorName())),
        body: const Center(child: Text('Please add a baby profile to view logs.')),
      );
    }

    // Filter out null values for the selected metric
    final filteredHistory = historyState.history
        .where((r) => _getRecordValue(r) != null)
        .toList()
        .reversed // Chronological order
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        color: AppColors.primary,
                        size: 24.r,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${_getSensorName()} History',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Range selection tabs
          Container(
            height: 48.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: HistoryTimeRange.values.length,
              itemBuilder: (context, index) {
                final range = HistoryTimeRange.values[index];
                final isSelected = historyState.selectedRange == range;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(range.label),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        if (range == HistoryTimeRange.custom) {
                          _showCustomRangePicker(baby.id);
                        } else {
                          ref.read(telemetryHistoryProvider.notifier).changeRange(baby.id, range);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : historyState.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.red),
                              SizedBox(height: 12.h),
                              Text(
                                historyState.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton(
                                onPressed: _loadHistory,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredHistory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 64.r,
                                  color: AppColors.textSecondary.withOpacity(0.3),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No data recorded for this time range.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Claymorphic Summary Vital Card
                                Container(
                                  padding: EdgeInsets.all(20.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: AppColors.softShadow,
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.05),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26.r,
                                        backgroundColor: _getSensorBgColor(),
                                        child: Icon(
                                          _getSensorIcon(),
                                          color: _getSensorColor(),
                                          size: 28.r,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getSensorName(),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  _getRecordValue(filteredHistory.last)!.toStringAsFixed(
                                                    widget.sensorType.contains('temp') ? 1 : 0,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 26.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  _getSensorUnit(),
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24.h),

                                // Zoom Control Slider
                                Row(
                                  children: [
                                    Icon(Icons.zoom_in_rounded, size: 18.r, color: AppColors.textSecondary),
                                    SizedBox(width: 6.w),
                                    Expanded(
                                      child: Text(
                                        'Scrollable Trend Graph',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Zoom: ',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(maxWidth: 120.w),
                                        height: 20.h,
                                        child: Slider(
                                          min: 1.0,
                                          max: 3.0,
                                          value: _zoomLevel,
                                          activeColor: AppColors.primary,
                                          inactiveColor: AppColors.divider,
                                          onChanged: (val) {
                                            setState(() {
                                              _zoomLevel = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),

                                // Horizontally Scrollable Chart Container
                                Container(
                                  height: 240.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  padding: EdgeInsets.only(top: 24.h, bottom: 16.h, right: 24.w, left: 12.w),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    reverse: true, // Start showing latest data on the right
                                    child: SizedBox(
                                      width: max(MediaQuery.of(context).size.width - 64.w, 400.w) * _zoomLevel,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: true,
                                            horizontalInterval: 20,
                                            verticalInterval: 1,
                                            getDrawingHorizontalLine: (value) => FlLine(
                                              color: AppColors.divider.withOpacity(0.5),
                                              strokeWidth: 1.r,
                                            ),
                                            getDrawingVerticalLine: (value) => FlLine(
                                              color: AppColors.divider.withOpacity(0.5),
                                              strokeWidth: 1.r,
                                            ),
                                          ),
                                          titlesData: FlTitlesData(
                                            show: true,
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30.h,
                                                interval: max(1.0, (filteredHistory.length / 5).floorToDouble()),
                                                getTitlesWidget: (value, meta) {
                                                  final idx = value.toInt();
                                                  if (idx >= 0 && idx < filteredHistory.length) {
                                                    final time = filteredHistory[idx].timestamp;
                                                    final hrStr = time.hour.toString().padLeft(2, '0');
                                                    final minStr = time.minute.toString().padLeft(2, '0');
                                                    return Padding(
                                                      padding: EdgeInsets.only(top: 8.h),
                                                      child: Text(
                                                        '$hrStr:$minStr',
                                                        style: TextStyle(
                                                          color: AppColors.textSecondary,
                                                          fontSize: 9.sp,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 36.w,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    value.toStringAsFixed(0),
                                                    style: TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 9.sp,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: List.generate(
                                                filteredHistory.length,
                                                (index) => FlSpot(
                                                  index.toDouble(),
                                                  _getRecordValue(filteredHistory[index])!,
                                                ),
                                              ),
                                              isCurved: true,
                                              color: _getSensorColor(),
                                              barWidth: 3.r,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: filteredHistory.length < 20,
                                                getDotPainter: (spot, percent, barData, index) =>
                                                    FlDotCirclePainter(
                                                  radius: 4.r,
                                                  color: _getSensorColor(),
                                                  strokeWidth: 1.5.r,
                                                  strokeColor: Colors.white,
                                                ),
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: _getSensorColor().withOpacity(0.08),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24.h),

                                // History Logs List Section
                                Text(
                                  'History Log',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: historyState.history.length,
                                  itemBuilder: (context, index) {
                                    final record = historyState.history[index];
                                    final val = _getRecordValue(record);
                                    if (val == null) return const SizedBox.shrink();

                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateTime(record.timestamp),
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                val.toStringAsFixed(
                                                  widget.sensorType.contains('temp') ? 1 : 0,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              SizedBox(width: 2.w),
                                              Text(
                                                _getSensorUnit(),
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
