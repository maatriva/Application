import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Spacing & Padding
  static const double paddingXS = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingDefault = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXL = 24.0;
  static const double paddingXXL = 28.0;

  // Spacing helper widgets
  static const SizedBox spacerXS = SizedBox(
    height: paddingXS,
    width: paddingXS,
  );
  static const SizedBox spacerSmall = SizedBox(
    height: paddingSmall,
    width: paddingSmall,
  );
  static const SizedBox spacerMedium = SizedBox(
    height: paddingMedium,
    width: paddingMedium,
  );
  static const SizedBox spacerDefault = SizedBox(
    height: paddingDefault,
    width: paddingDefault,
  );
  static const SizedBox spacerLarge = SizedBox(
    height: paddingLarge,
    width: paddingLarge,
  );
  static const SizedBox spacerXL = SizedBox(
    height: paddingXL,
    width: paddingXL,
  );
  static const SizedBox spacerXXL = SizedBox(
    height: paddingXXL,
    width: paddingXXL,
  );

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusDefault = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXL = 32.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(
    radiusSmall,
  );
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(
    radiusMedium,
  );
  static final BorderRadius borderRadiusDefault = BorderRadius.circular(
    radiusDefault,
  );
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(
    radiusLarge,
  );
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationDefault = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Asset Paths
  static const String logoPath = 'assets/images/MaatrivaFavicon.png';
  static const String defaultAvatarPath = 'assets/default_avatar.png';
}
