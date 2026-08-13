import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';

/// Real-Time Countdown Flip Clock Widget.
/// Computes remaining time based on [targetExpiry] (expiresAt) and server/current time.
/// Displays HOURS : MINUTES : SECONDS (or DAYS : HOURS : MINUTES if >= 24h).
/// Features 3D flip card digit transitions as time ticks down.
class CountdownFlipClock extends StatefulWidget {
  final DateTime targetExpiry;
  final Duration serverClockOffset;
  final VoidCallback? onExpired;

  const CountdownFlipClock({
    super.key,
    required this.targetExpiry,
    this.serverClockOffset = Duration.zero,
    this.onExpired,
  });

  @override
  State<CountdownFlipClock> createState() => _CountdownFlipClockState();
}

class _CountdownFlipClockState extends State<CountdownFlipClock> {
  Timer? _timer;
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startCountdown();
  }

  @override
  void didUpdateWidget(CountdownFlipClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetExpiry != oldWidget.targetExpiry) {
      _calculateRemainingTime();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final now = DateTime.now().add(widget.serverClockOffset);
    final remaining = widget.targetExpiry.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      if (!_isExpired) {
        setState(() {
          _days = 0;
          _hours = 0;
          _minutes = 0;
          _seconds = 0;
          _isExpired = true;
        });
        if (widget.onExpired != null) {
          widget.onExpired!();
        }
      }
      return;
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (mounted) {
      setState(() {
        _days = days;
        _hours = hours;
        _minutes = minutes;
        _seconds = seconds;
        _isExpired = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showDays = _days > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.predictiveCardBg, // Pale aqua #EAF8F7
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: AppColors.predictiveClayShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 14.r,
                color: AppColors.primary,
              ),
              SizedBox(width: 6.w),
              Text(
                'TIME REMAINING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showDays) ...[
                _buildFlipCard(label: 'DAYS', value: _days),
                _buildColon(),
                _buildFlipCard(label: 'HOURS', value: _hours),
                _buildColon(),
                _buildFlipCard(label: 'MIN', value: _minutes),
              ] else ...[
                _buildFlipCard(label: 'HOURS', value: _hours),
                _buildColon(),
                _buildFlipCard(label: 'MINUTES', value: _minutes),
                _buildColon(),
                _buildFlipCard(label: 'SECONDS', value: _seconds),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColon() {
    return Text(
      ':',
      style: GoogleFonts.outfit(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF173A70).withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildFlipCard({required String label, required int value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72.w,
          height: 78.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173A70).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D Animated Flip Digit
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
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF173A70),
                  ),
                ),
              ),

              // Split Divider Line
              Positioned(
                left: 0,
                right: 0,
                child: Container(
                  height: 1.2.h,
                  color: const Color(0xFFD0ECED),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
