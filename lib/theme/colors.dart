import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Canvas
  static const Color background = Color(0xFFFBF8FD);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFEFEAF5);

  // Brand Colors
  static const Color primary = Color(0xFF6E3DE0);
  static const Color primaryLight = Color(0xFFEBE3FC);
  static const Color textPrimary = Color(0xFF1E0E3D);
  static const Color textSecondary = Color(0xFF655B75);

  // Status Chip Colors
  static const Color sleepBg = Color(0xFFE2F3EC);
  static const Color sleepText = Color(0xFF128054);

  static const Color healthBg = Color(0xFFF3EDFA);
  static const Color healthText = Color(0xFF8143D1);

  static const Color connectBg = Color(0xFFE5EFFB);
  static const Color connectText = Color(0xFF1866C5);

  // Today's Summary Circular Icon Backgrounds & Colors
  static const Color tempBg = Color(0xFFE8F0FE);
  static const Color tempIcon = Color(0xFF1A73E8);

  static const Color heartBg = Color(0xFFFDE8E8);
  static const Color heartIcon = Color(0xFFE02424);

  static const Color sleepProgressBg = Color(0xFFF3E8FF);
  static const Color sleepProgressIcon = Color(0xFF7E3AF2);

  static const Color cryBg = Color(0xFFE1F8F5);
  static const Color cryIcon = Color(0xFF0E9F6E);

  // Soft Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF5D2EC0).withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF5D2EC0).withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
