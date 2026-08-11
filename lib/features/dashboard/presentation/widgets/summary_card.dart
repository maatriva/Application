import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.clayShadow,
          border: Border.all(
            color: AppColors.softTeal.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double height = constraints.maxHeight;
            // Adjust sizes based on constraints
            final double iconSize = height > 110 ? 44.0 : 32.0;
            final double spacing = height > 110 ? 8.0 : 4.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: iconSize * 0.5),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: height > 110 ? 11 : 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.metricValue.copyWith(
                          fontSize: height > 110 ? 20 : 16,
                        ),
                        children: [
                          TextSpan(text: value),
                          if (unit.isNotEmpty) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: unit,
                              style: AppTypography.metricUnit.copyWith(
                                fontSize: height > 110 ? 12 : 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
