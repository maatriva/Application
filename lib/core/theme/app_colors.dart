import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Canvas (Soft Aqua / Light Cyan)
  static const Color background = Color(0xFFEBF7F8);
  static const Color backgroundLight = Color(0xFFF3FAFA);
  static const Color softTeal = Color(0xFFB9E4E5);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFD6EDEE);

  // Brand Colors (Periwinkle Blue & Soft Lavender)
  static const Color primary = Color(0xFF5E7FE0);
  static const Color primaryDark = Color(0xFF4362C8);
  static const Color secondary = Color(0xFF8B9FEA);
  static const Color primaryLight = Color(0xFFEBF0FC);
  static const Color lavender = Color(0xFFDCD7FA);

  // Typography (Deep Navy & Muted Blue-Gray)
  static const Color textPrimary = Color(0xFF173A70);
  static const Color textSecondary = Color(0xFF66758F);
  static const Color textMuted = Color(0xFF8A99B3);

  // Status Chip & Healthcare Colors
  static const Color sleepBg = Color(0xFFE3F6F5);
  static const Color sleepText = Color(0xFF1B8A7E);

  static const Color healthBg = Color(0xFFEBF0FC);
  static const Color healthText = Color(0xFF5E7FE0);

  static const Color connectBg = Color(0xFFE0F4F5);
  static const Color connectText = Color(0xFF173A70);

  // Summary Metrics Circular Backgrounds & Icons
  static const Color tempBg = Color(0xFFE8F4FF);
  static const Color tempIcon = Color(0xFF4A89F3);

  static const Color heartBg = Color(0xFFFFECEE);
  static const Color heartIcon = Color(0xFFEE5265);

  static const Color sleepProgressBg = Color(0xFFEDEBFD);
  static const Color sleepProgressIcon = Color(0xFF7060E6);

  static const Color cryBg = Color(0xFFE3F7F5);
  static const Color cryIcon = Color(0xFF19A394);

  // Claymorphism Soft Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF5E7FE0).withValues(alpha: 0.08),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF173A70).withValues(alpha: 0.03),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> clayShadow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 10,
      spreadRadius: -2,
      offset: const Offset(-4, -4),
    ),
    BoxShadow(
      color: const Color(0xFF173A70).withValues(alpha: 0.06),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(4, 8),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B87EB), Color(0xFF4F6ED6)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6F5F6), Color(0xFFF2FAF8)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF7FCFC)],
  );
}
