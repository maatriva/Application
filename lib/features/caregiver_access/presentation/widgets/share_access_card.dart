import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'qr_code_card.dart';

class ShareAccessCard extends StatelessWidget {
  final String qrToken;
  final bool isLoading;

  const ShareAccessCard({
    super.key,
    required this.qrToken,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.02),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // QR Code with Rounded Dashed Border & "SCAN ME" badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Dashed Border Outline
              CustomPaint(
                painter: DashedBorderPainter(
                  color: AppColors.primary.withOpacity(0.25),
                  strokeWidth: 2,
                  dashWidth: 6,
                  dashSpace: 4,
                  radius: 28,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: QRCodeCard(qrToken: qrToken, isLoading: isLoading),
                ),
              ),

              // "SCAN ME" Badge positioned on the top right
              Positioned(
                top: 4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'SCAN ME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Instant Scan Title
          const Text(
            'INSTANT SCAN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle description
          const Text(
            'Let them scan this code to join instantly.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a perfect rounded dashed border around the QR
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );

    // Render path with dashes
    final List<PathMetric> pathMetrics = path.computeMetrics().toList();
    for (var pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double length = math.min(dashWidth, pathMetric.length - distance);
        final Path extractPath = pathMetric.extractPath(
          distance,
          distance + length,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
