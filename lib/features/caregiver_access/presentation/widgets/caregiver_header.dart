import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class CaregiverHeader extends StatelessWidget {
  const CaregiverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant title in Playfair Display
          Text(
            'Share Access',
            style: AppTypography.displayHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Refined subtitle in Inter
          const Text(
            'Securely invite a temporary caregiver or family member.',
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
