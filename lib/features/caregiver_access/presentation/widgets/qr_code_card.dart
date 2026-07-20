import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class QRCodeCard extends StatelessWidget {
  final String qrToken;
  final bool isLoading;

  const QRCodeCard({super.key, required this.qrToken, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const SizedBox(
              height: 200,
              width: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Container(
              height: 200,
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: QRPainter(
                  token: qrToken,
                  primaryColor: AppColors.primary,
                ),
              ),
            ),
    );
  }
}

class QRPainter extends CustomPainter {
  final String token;
  final Color primaryColor;

  QRPainter({required this.token, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = primaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      lightPaint,
    );

    final double padding = 8.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);

    // Number of modules in mock QR
    final int modulesCount = 21;
    final double moduleSize = drawWidth / modulesCount;

    // Helper to draw a square anchor at (col, row) with width/height in modules
    void drawAnchor(int col, int row) {
      final double x = padding + (col * moduleSize);
      final double y = padding + (row * moduleSize);
      final double outerSize = moduleSize * 7;
      final double innerSize = moduleSize * 3;
      final double offset = moduleSize * 2;

      // Outer block
      paint.color = primaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, outerSize, outerSize),
          const Radius.circular(4),
        ),
        paint,
      );

      // Inner space (white background or light canvas)
      paint.color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(
          x + moduleSize,
          y + moduleSize,
          moduleSize * 5,
          moduleSize * 5,
        ),
        paint,
      );

      // Inner solid block
      paint.color = primaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + offset, y + offset, innerSize, innerSize),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    // 1. Draw 3 main anchors (top-left, top-right, bottom-left)
    drawAnchor(0, 0); // Top-left
    drawAnchor(modulesCount - 7, 0); // Top-right
    drawAnchor(0, modulesCount - 7); // Bottom-left

    // 2. Draw mock QR random modules
    // Use stable mock random based on the token string to keep QR static for same state
    final int seed = token.hashCode;
    final random = math.Random(seed);

    paint.color = primaryColor;
    for (int r = 0; r < modulesCount; r++) {
      for (int c = 0; c < modulesCount; c++) {
        // Skip Anchor areas
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= modulesCount - 8) ||
            (r >= modulesCount - 8 && c < 8)) {
          continue;
        }

        // Skip center logo area (modules from 8 to 12)
        if (r >= 8 && r <= 12 && c >= 8 && c <= 12) {
          continue;
        }

        // Draw module based on deterministic pseudo-random logic
        if (random.nextDouble() > 0.45) {
          final double mx = padding + (c * moduleSize);
          final double my = padding + (r * moduleSize);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(mx + 1, my + 1, moduleSize - 2, moduleSize - 2),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }

    // 3. Draw a gorgeous central heart emblem with circular badge
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double badgeRadius = moduleSize * 3;

    // Draw white background circle for center badge
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), badgeRadius, paint);

    // Draw light violet border / inner circle
    paint.color = primaryColor.withOpacity(0.12);
    canvas.drawCircle(Offset(cx, cy), badgeRadius - 1.5, paint);

    // Draw central heart shape in primary color
    paint.color = primaryColor;
    final heartPath = Path();
    final double width = badgeRadius * 1.1;
    final double height = badgeRadius * 1.1;

    heartPath.moveTo(cx, cy + height * 0.35);
    // Left curve
    heartPath.cubicTo(
      cx - width * 0.55,
      cy - height * 0.15,
      cx - width * 0.4,
      cy - height * 0.6,
      cx,
      cy - height * 0.2,
    );
    // Right curve
    heartPath.cubicTo(
      cx,
      cy - height * 0.2,
      cx + width * 0.4,
      cy - height * 0.6,
      cx + width * 0.55,
      cy - height * 0.15,
    );
    heartPath.close();

    canvas.drawPath(heartPath, paint);
  }

  @override
  bool shouldRepaint(covariant QRPainter oldDelegate) {
    return oldDelegate.token != token;
  }
}
