import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';

class AIInsightCard extends StatelessWidget {
  final String insight;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AIInsightCard({
    super.key,
    required this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDFA), // Soft lavender background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant rounded block icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Insight Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Insight',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onRefresh != null)
                      GestureDetector(
                        onTap: isLoading ? null : onRefresh,
                        child: AnimatedRotation(
                          turns: isLoading ? 1 : 0,
                          duration: const Duration(seconds: 1),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Color(0xFFEBE3FC),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    insight,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
