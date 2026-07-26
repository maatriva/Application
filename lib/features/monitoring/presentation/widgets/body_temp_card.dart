import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';

class BodyTempCard extends ConsumerWidget {
  const BodyTempCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final telemetryMap = dashboardState.latestTelemetry;
    final tempVal = telemetryMap?['body_temperature']?.value;
    final tempText = tempVal != null ? '${tempVal.toStringAsFixed(1)}°' : '36.5°';

    // Map temperature to painter range (normal: 36.5 - 37.5)
    double progress = 0.72;
    if (tempVal != null) {
      // Scale temperature from 35.0 - 39.0 to 0.0 - 1.0 progress
      progress = ((tempVal - 35.0) / 4.0).clamp(0.0, 1.0);
    }

    final isNormal = tempVal == null || (tempVal >= 36.2 && tempVal <= 37.8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Label and status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNormal ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isNormal ? 'NORMAL' : 'ALERT',
                  style: TextStyle(
                    color: isNormal ? const Color(0xFF1E88E5) : const Color(0xFFC62828),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Circular Ring with Value
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CustomPaint(
                      painter: TemperatureCirclePainter(value: progress),
                    ),
                  ),
                  Text(
                    tempText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Label
          const Text(
            'Body Temp',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureCirclePainter extends CustomPainter {
  final double value;

  TemperatureCirclePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final progressPaint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 3, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
