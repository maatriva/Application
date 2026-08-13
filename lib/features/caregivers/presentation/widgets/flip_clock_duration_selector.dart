import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';

/// Premium Interactive 3-Column Flip Clock Duration Selector.
///
/// Features:
/// - 3 Columns: DAYS (0-7), HOURS (0-23), MINUTES (0-59)
/// - Maatriva claymorphism styling: Soft pale aqua surface (#EAF8F7), navy text, soft depth shadows
/// - Smooth 250ms flip digit animation
/// - Vertical swipe, tap step (+ / -), and wheel interactions
/// - Automatic minute -> hour (60m -> 1h) and hour -> day (24h -> 1d) normalization
/// - Hard maximum limit of 7 DAYS (7d 0h 0m = 10080 minutes)
/// - Total access time summary omitting zero components
/// - Quick preset buttons (15m, 30m, 1h, 2h, 1d, 3d, 7d)
class FlipClockDurationSelector extends StatefulWidget {
  final String initialDurationLabel;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<int>? onTotalMinutesChanged;
  final VoidCallback? onConfirm;
  final String title;
  final bool showConfirmButton;
  final bool isCaregiverLocked;

  const FlipClockDurationSelector({
    super.key,
    this.initialDurationLabel = '30 Mins',
    required this.onDurationChanged,
    this.onTotalMinutesChanged,
    this.onConfirm,
    this.title = 'ACCESS DURATION',
    this.showConfirmButton = false,
    this.isCaregiverLocked = false,
  });

  @override
  State<FlipClockDurationSelector> createState() =>
      _FlipClockDurationSelectorState();
}

class _FlipClockDurationSelectorState
    extends State<FlipClockDurationSelector> {
  int _days = 0;
  int _hours = 0;
  int _minutes = 30;

  @override
  void initState() {
    super.initState();
    _parseInitialLabel(widget.initialDurationLabel);
  }

  @override
  void didUpdateWidget(FlipClockDurationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDurationLabel != oldWidget.initialDurationLabel) {
      _parseInitialLabel(widget.initialDurationLabel);
    }
  }

  void _parseInitialLabel(String label) {
    final lower = label.toLowerCase().trim();
    int days = 0;
    int hours = 0;
    int mins = 0;

    final daysMatch = RegExp(r'(\d+)\s*(?:days|day|d)').firstMatch(lower);
    final hoursMatch = RegExp(r'(\d+)\s*(?:hours|hour|hrs|hr|h)').firstMatch(lower);
    final minsMatch = RegExp(r'(\d+)\s*(?:minutes|minute|mins|min|m)').firstMatch(lower);

    if (daysMatch != null) {
      days = int.tryParse(daysMatch.group(1) ?? '0') ?? 0;
    }
    if (hoursMatch != null) {
      hours = int.tryParse(hoursMatch.group(1) ?? '0') ?? 0;
    }
    if (minsMatch != null) {
      mins = int.tryParse(minsMatch.group(1) ?? '0') ?? 0;
    } else if (daysMatch == null && hoursMatch == null) {
      final numMatch = RegExp(r'(\d+)').firstMatch(lower);
      if (numMatch != null) {
        final val = int.tryParse(numMatch.group(1) ?? '30') ?? 30;
        if (lower.contains('hour') || lower.contains('hr')) {
          hours = val;
        } else if (lower.contains('day')) {
          days = val;
        } else {
          mins = val;
        }
      }
    }

    _updateDuration(days: days, hours: hours, minutes: mins, notify: false);
  }

  /// Core mathematical normalization and clamping engine.
  /// Enforces:
  /// 1. 60 mins -> +1 hour, 24 hours -> +1 day
  /// 2. Hard maximum of 7 days (10080 minutes)
  /// 3. Minimum of 0 minutes
  void _updateDuration({
    int? days,
    int? hours,
    int? minutes,
    bool notify = true,
  }) {
    if (widget.isCaregiverLocked) return;

    int d = days ?? _days;
    int h = hours ?? _hours;
    int m = minutes ?? _minutes;

    // Calculate total minutes
    int totalMins = (d * 1440) + (h * 60) + m;

    // Hard Clamp [0, 10080 minutes] (7 days max)
    if (totalMins < 0) totalMins = 0;
    if (totalMins > 10080) totalMins = 10080;

    // Normalize into Days, Hours, Minutes
    final normDays = totalMins ~/ 1440;
    final remAfterDays = totalMins % 1440;
    final normHours = remAfterDays ~/ 60;
    final normMins = remAfterDays % 60;

    setState(() {
      _days = normDays;
      _hours = normHours;
      _minutes = normMins;
    });

    if (notify) {
      final formattedLabel = _getFormattedLabel();
      widget.onDurationChanged(formattedLabel);
      if (widget.onTotalMinutesChanged != null) {
        widget.onTotalMinutesChanged!(totalMins);
      }
    }
  }

  int get _totalMinutes => (_days * 1440) + (_hours * 60) + _minutes;

  String _getFormattedLabel() {
    if (_totalMinutes == 0) return '0 Mins';
    if (_days > 0 && _hours == 0 && _minutes == 0) {
      return '$_days ${_days == 1 ? 'Day' : 'Days'}';
    }
    if (_days == 0 && _hours > 0 && _minutes == 0) {
      return '$_hours ${_hours == 1 ? 'Hour' : 'Hours'}';
    }
    if (_days == 0 && _hours == 0 && _minutes > 0) {
      return '$_minutes Mins';
    }

    final parts = <String>[];
    if (_days > 0) parts.add('${_days}d');
    if (_hours > 0) parts.add('${_hours}h');
    if (_minutes > 0) parts.add('${_minutes}m');
    return parts.join(' ');
  }

  String _formatTotalSummary() {
    if (_totalMinutes == 0) return '0 minutes selected';
    final parts = <String>[];
    if (_days > 0) {
      parts.add('$_days ${_days == 1 ? 'day' : 'days'}');
    }
    if (_hours > 0) {
      parts.add('$_hours ${_hours == 1 ? 'hour' : 'hours'}');
    }
    if (_minutes > 0) {
      parts.add('$_minutes ${_minutes == 1 ? 'minute' : 'minutes'}');
    }
    return parts.join(' • ');
  }

  void _applyPreset(int minutes) {
    int d = minutes ~/ 1440;
    int rem = minutes % 1440;
    int h = rem ~/ 60;
    int m = rem % 60;
    _updateDuration(days: d, hours: h, minutes: m);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.predictiveCardBg, // Soft pale aqua #EAF8F7
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: AppColors.predictiveClayShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Title
          Text(
            widget.title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16.h),

          // Caregiver Restricted Notice if applicable
          if (widget.isCaregiverLocked) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 6.w),
                  Text(
                    'Access Duration Managed by Parent',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // 3-Column Flip Clock Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFlipColumn(
                label: 'DAYS',
                value: _days,
                maxVal: 7,
                onIncrement: () => _updateDuration(days: _days + 1),
                onDecrement: () => _updateDuration(days: _days - 1),
                onChanged: (val) => _updateDuration(days: val),
              ),
              _buildColonSeparator(),
              _buildFlipColumn(
                label: 'HOURS',
                value: _hours,
                maxVal: 23,
                onIncrement: () => _updateDuration(hours: _hours + 1),
                onDecrement: () => _updateDuration(hours: _hours - 1),
                onChanged: (val) => _updateDuration(hours: val),
              ),
              _buildColonSeparator(),
              _buildFlipColumn(
                label: 'MINUTES',
                value: _minutes,
                maxVal: 59,
                onIncrement: () => _updateDuration(minutes: _minutes + 1),
                onDecrement: () => _updateDuration(minutes: _minutes - 1),
                onChanged: (val) => _updateDuration(minutes: val),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Total Duration Summary Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: _totalMinutes == 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFBBE5E7),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _totalMinutes == 0
                      ? Icons.warning_amber_rounded
                      : Icons.timer_outlined,
                  size: 18.r,
                  color: _totalMinutes == 0
                      ? const Color(0xFFEF4444)
                      : AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    _totalMinutes == 0
                        ? 'Please select an access duration.'
                        : _formatTotalSummary(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: _totalMinutes == 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF173A70),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Quick Preset Shortcuts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildPresetChip('15m', 15),
                _buildPresetChip('30m', 30),
                _buildPresetChip('1h', 60),
                _buildPresetChip('2h', 120),
                _buildPresetChip('1d', 1440),
                _buildPresetChip('3d', 4320),
                _buildPresetChip('7d', 10080),
              ],
            ),
          ),

          if (widget.showConfirmButton) ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _totalMinutes > 0 && !widget.isCaregiverLocked
                    ? () {
                        if (widget.onConfirm != null) {
                          widget.onConfirm!();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColonSeparator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Text(
        ':',
        style: GoogleFonts.outfit(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF173A70).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int totalMins) {
    final isSelected = _totalMinutes == totalMins;

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: widget.isCaregiverLocked ? null : () => _applyPreset(totalMins),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1.2,
            ),
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
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlipColumn({
    required String label,
    required int value,
    required int maxVal,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        // Ascend (Up) Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isCaregiverLocked ? null : onIncrement,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: 54.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: widget.isCaregiverLocked
                      ? Colors.grey.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF173A70).withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: widget.isCaregiverLocked
                      ? Colors.grey
                      : AppColors.primary,
                  size: 24.r,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),

        // Vertical Swipeable & Tappable Flip Card Box
        GestureDetector(
          onVerticalDragEnd: widget.isCaregiverLocked
              ? null
              : (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -80) {
                      onIncrement(); // Ascend
                    } else if (details.primaryVelocity! > 80) {
                      onDecrement(); // Descend
                    }
                  }
                },
          child: Container(
            width: 84.w,
            height: 96.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.95),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173A70).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 6,
                  offset: const Offset(-3, -3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Flip Digit
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    final rotate = Tween<double>(begin: math.pi / 2, end: 0.0)
                        .animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      builder: (context, childWidget) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateX(rotate.value),
                          alignment: Alignment.center,
                          child: childWidget,
                        );
                      },
                      child: child,
                    );
                  },
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    key: ValueKey<int>(value),
                    style: GoogleFonts.outfit(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF173A70),
                    ),
                  ),
                ),

                // Center Split Flip Line
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.5.h,
                    color: const Color(0xFFD0ECED),
                  ),
                ),

                // Top Half Tap Zone -> Ascend (Increment)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 48.h,
                  child: GestureDetector(
                    onTap: widget.isCaregiverLocked ? null : onIncrement,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),

                // Bottom Half Tap Zone -> Descend (Decrement)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 48.h,
                  child: GestureDetector(
                    onTap: widget.isCaregiverLocked ? null : onDecrement,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.h),

        // Descend (Down) Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isCaregiverLocked ? null : onDecrement,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: 54.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: widget.isCaregiverLocked
                      ? Colors.grey.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF173A70).withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: widget.isCaregiverLocked
                      ? Colors.grey
                      : AppColors.primary,
                  size: 24.r,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 4.h),

        // Column Label
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Modal Bottom Sheet helper for launching FlipClockDurationSelector.
class FlipClockDurationSelectorModal extends StatelessWidget {
  final String initialLabel;
  final String title;
  final ValueChanged<String> onDurationConfirmed;

  const FlipClockDurationSelectorModal({
    super.key,
    required this.initialLabel,
    required this.title,
    required this.onDurationConfirmed,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialLabel,
    String title = 'SELECT ACCESS DURATION',
    ValueChanged<String>? onDurationSelected,
  }) {
    String currentLabel = initialLabel;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.predictiveCanvasBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  FlipClockDurationSelector(
                    title: title,
                    initialDurationLabel: initialLabel,
                    showConfirmButton: true,
                    onDurationChanged: (newLabel) {
                      currentLabel = newLabel;
                      if (onDurationSelected != null) {
                        onDurationSelected(newLabel);
                      }
                    },
                    onConfirm: () {
                      Navigator.pop(sheetContext, currentLabel);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
