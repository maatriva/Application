import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';

class CaregiverHeader extends StatelessWidget {
  const CaregiverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant title in Playfair Display / Outfit
          Text(
            'Caregiver Access',
            style: AppTypography.displayHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Refined subtitle
          const Text(
            'Securely share temporary access to your baby\'s care.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

