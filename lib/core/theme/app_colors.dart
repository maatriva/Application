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
      color: const Color(0xFF5478E8).withValues(alpha: 0.08),
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
      color: Colors.white.withValues(alpha: 0.95),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(-5, -5),
    ),
    BoxShadow(
      color: const Color(0xFF173A70).withValues(alpha: 0.08),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(5, 9),
    ),
  ];

  static List<BoxShadow> clayHeroShadow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 16,
      spreadRadius: -3,
      offset: const Offset(-6, -6),
    ),
    BoxShadow(
      color: const Color(0xFF5478E8).withValues(alpha: 0.15),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(6, 12),
    ),
  ];

  // Specific Prompt Brand Color Aliases
  static const Color aquaBg = Color(0xFFEAFBFC);
  static const Color aquaSoft = Color(0xFFDDF6F7);
  static const Color aquaMint = Color(0xFFC9EEF0);
  static const Color royalBlue = Color(0xFF5478E8);
  static const Color royalBlueLight = Color(0xFF617FEA);
  static const Color periwinkle = Color(0xFF6B82E8);
  static const Color navyDeep = Color(0xFF173A70);
  static const Color navyMedium = Color(0xFF1D3B70);
  static const Color navyDark = Color(0xFF233F70);
  static const Color lavenderAccent = Color(0xFFA98BFF);
  static const Color lavenderLight = Color(0xFFB69CFF);
  static const Color softMint = Color(0xFFDDF7ED);
  static const Color softWarmAccent = Color(0xFFFFF3E0);
  static const Color warmOrange = Color(0xFFFF9F43);

  // Predictive Health Unified Design Tokens
  static const Color predictiveCardBg = Color(0xFFEAF8F7);
  static const Color predictiveCanvasBg = Color(0xFFDFF3F4);

  static List<BoxShadow> predictiveClayShadow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 14,
      spreadRadius: -2,
      offset: const Offset(-4, -4),
    ),
    BoxShadow(
      color: const Color(0xFF173A70).withValues(alpha: 0.07),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(4, 8),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5478E8), Color(0xFF6B82E8)],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF3FBFC),
      Color(0xFFEEF7FF),
    ],
  );

  static const LinearGradient cradleCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF4FAFC),
      Color(0xFFEDF4FE),
    ],
  );

  static const LinearGradient aiInsightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFDF8),
      Color(0xFFF7F8FE),
      Color(0xFFF0F6FF),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAFBFC), Color(0xFFF4FAFA)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF7FCFC)],
  );
}
