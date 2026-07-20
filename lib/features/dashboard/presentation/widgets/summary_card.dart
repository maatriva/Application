import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Icon background
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          // Biometric label (e.g. Temperature)
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Biometric value with unit (e.g. 24 °C)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.metricValue,
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty) ...[
                  const TextSpan(text: ' '),
                  TextSpan(text: unit, style: AppTypography.metricUnit),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
