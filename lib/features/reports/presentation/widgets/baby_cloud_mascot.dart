import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A custom baby-friendly illustration of a sleeping baby resting peacefully
/// on a cloud under starry skies with a subtle Maatriva AI mascot.
class BabyCloudMascot extends StatelessWidget {
  final double width;
  final double height;

  const BabyCloudMascot({
    super.key,
    this.width = 140,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      height: height.h,
      child: CustomPaint(
        painter: _BabyCloudPainter(),
      ),
    );
  }
}

class _BabyCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // 1. Draw soft starry background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC084FC).withValues(alpha: 0.25),
          const Color(0xFF818CF8).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawCircle(center, size.width * 0.45, glowPaint);

    // 2. Draw Stars & Moon
    _drawStarsAndMoon(canvas, size);

    // 3. Draw Fluffy Base Cloud
    final cloudPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cloudShadowPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Cloud base path using circles
    final cloudY = size.height * 0.7;

    // Cloud shadow
    canvas.drawCircle(Offset(size.width * 0.3, cloudY), 24.r, cloudShadowPaint);
    canvas.drawCircle(Offset(size.width * 0.5, cloudY - 8.h), 32.r, cloudShadowPaint);
    canvas.drawCircle(Offset(size.width * 0.7, cloudY), 24.r, cloudShadowPaint);

    // Cloud white body
    canvas.drawCircle(Offset(size.width * 0.22, cloudY + 4.h), 20.r, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.38, cloudY - 6.h), 28.r, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.56, cloudY - 10.h), 32.r, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.74, cloudY - 2.h), 24.r, cloudPaint);
    canvas.drawRRect(
      RRect.fromLTRBR(
        size.width * 0.18,
        cloudY - 4.h,
        size.width * 0.82,
        cloudY + 16.h,
        Radius.circular(20.r),
      ),
      cloudPaint,
    );

    // 4. Draw Sleeping Baby Head & Onesie
    final headCenter = Offset(size.width * 0.52, size.height * 0.42);
    final headRadius = 22.r;

    // Baby body/onesie (soft cyan/mint gradient)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromLTRBR(
        headCenter.dx - 16.w,
        headCenter.dy + 8.h,
        headCenter.dx + 28.w,
        headCenter.dy + 26.h,
        Radius.circular(16.r),
      ),
      bodyPaint,
    );

    // Baby head (warm skin tone)
    final skinPaint = Paint()..color = const Color(0xFFFFD1B3);
    canvas.drawCircle(headCenter, headRadius, skinPaint);

    // Cute rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFDA4AF).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(headCenter.dx - 8.w, headCenter.dy + 4.h), 4.r, cheekPaint);
    canvas.drawCircle(Offset(headCenter.dx + 10.w, headCenter.dy + 4.h), 4.r, cheekPaint);

    // Closed sleeping eyes (arc)
    final eyePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w
      ..strokeCap = StrokeCap.round;

    final leftEyePath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(headCenter.dx - 8.w, headCenter.dy - 2.h), radius: 4.r),
        0.2,
        math.pi - 0.4,
      );
    final rightEyePath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(headCenter.dx + 8.w, headCenter.dy - 2.h), radius: 4.r),
        0.2,
        math.pi - 0.4,
      );

    canvas.drawPath(leftEyePath, eyePaint);
    canvas.drawPath(rightEyePath, eyePaint);

    // Baby sleep cap (cute lavender nightcap)
    final capPaint = Paint()
      ..shader = const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final capPath = Path()
      ..moveTo(headCenter.dx - headRadius + 2.w, headCenter.dy - 6.h)
      ..cubicTo(
        headCenter.dx - 10.w,
        headCenter.dy - headRadius - 16.h,
        headCenter.dx + 20.w,
        headCenter.dy - headRadius - 16.h,
        headCenter.dx + headRadius - 2.w,
        headCenter.dy - 6.h,
      )
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Cap pom-pom
    final pomPomPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx + 18.w, headCenter.dy - headRadius - 12.h), 5.r, pomPomPaint);

    // 5. Draw Floating AI Mascot Sparkle
    _drawAiSparkleMascot(canvas, size);
  }

  void _drawStarsAndMoon(Canvas canvas, Size size) {
    // Crescent Moon on top right
    final moonPaint = Paint()..color = const Color(0xFFFDE047);
    final moonCenter = Offset(size.width * 0.82, size.height * 0.22);
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: 10.r));
    final moonCut = Path()
      ..addOval(Rect.fromCircle(center: Offset(moonCenter.dx - 4.w, moonCenter.dy - 3.h), radius: 9.r));
    final crescent = Path.combine(PathOperation.difference, moonPath, moonCut);
    canvas.drawPath(crescent, moonPaint);

    // Small stars
    final starPaint = Paint()..color = const Color(0xFFFACC15).withValues(alpha: 0.8);
    _drawStar(canvas, Offset(size.width * 0.18, size.height * 0.22), 4.r, starPaint);
    _drawStar(canvas, Offset(size.width * 0.35, size.height * 0.16), 3.r, starPaint);
    _drawStar(canvas, Offset(size.width * 0.72, size.height * 0.12), 4.r, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final p1 = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      final midAngle = angle + math.pi / 4;
      final p2 = Offset(center.dx + math.cos(midAngle) * (radius * 0.3), center.dy + math.sin(midAngle) * (radius * 0.3));
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawAiSparkleMascot(Canvas canvas, Size size) {
    final robotCenter = Offset(size.width * 0.2, size.height * 0.42);

    // Robot body (Soft purple AI mascot pill)
    final botPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: robotCenter, width: 22.w, height: 18.h),
        Radius.circular(8.r),
      ),
      botPaint,
    );

    // Robot face visor
    final visorPaint = Paint()..color = const Color(0xFF1E1B4B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(robotCenter.dx, robotCenter.dy - 1.h), width: 16.w, height: 10.h),
        Radius.circular(5.r),
      ),
      visorPaint,
    );

    // Robot cyan eyes
    final eyePaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(robotCenter.dx - 3.w, robotCenter.dy - 1.h), 1.5.r, eyePaint);
    canvas.drawCircle(Offset(robotCenter.dx + 3.w, robotCenter.dy - 1.h), 1.5.r, eyePaint);

    // Robot antenna
    final antennaPaint = Paint()
      ..color = const Color(0xFFC084FC)
      ..strokeWidth = 1.5.w;
    canvas.drawLine(
      Offset(robotCenter.dx, robotCenter.dy - 9.h),
      Offset(robotCenter.dx, robotCenter.dy - 13.h),
      antennaPaint,
    );
    canvas.drawCircle(Offset(robotCenter.dx, robotCenter.dy - 14.h), 2.r, Paint()..color = const Color(0xFFFDE047));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
