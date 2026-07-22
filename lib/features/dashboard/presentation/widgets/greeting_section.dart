import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';

class GreetingSection extends StatelessWidget {
  final String motherName;
  final String babyStatus;

  const GreetingSection({
    super.key,
    required this.motherName,
    required this.babyStatus,
  });

  @override
  Widget build(BuildContext context) {
    String subtext = "Your little one is having a peaceful morning.";
    if (babyStatus.toLowerCase() == 'crying' ||
        babyStatus.toLowerCase() == 'awake') {
      subtext = "Your little one is awake and needs your attention.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good Morning, $motherName', style: AppTypography.displayHeader),
        const SizedBox(height: 6),
        Text(
          subtext,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
