import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/clay_container.dart';

/// Premium Maatriva AI Insight Card.
/// Features soft warm cream/aqua background, "AI" badge, subtle glow,
/// dynamic telemetry insight text, and "View details →" action.
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
    return ClayContainer(
      borderRadius: 26,
      gradient: AppColors.aiInsightGradient,
      shadows: AppColors.clayShadow,
      border: Border.all(
        color: AppColors.lavenderAccent.withValues(alpha: 0.25),
        width: 1.2,
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background subtle sparkle icon decoration
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 60,
              color: AppColors.warmOrange.withValues(alpha: 0.06),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: ✨ Maatriva Insight + AI Badge + Refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.softWarmAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmOrange.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.warmOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '✨ Maatriva Insight',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // AI Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.royalBlue, AppColors.lavenderAccent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (onRefresh != null)
                    GestureDetector(
                      onTap: isLoading ? null : onRefresh,
                      child: AnimatedRotation(
                        turns: isLoading ? 1 : 0,
                        duration: const Duration(seconds: 1),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.royalBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Insight Body Text
              if (isLoading) ...[
                const LinearProgressIndicator(
                  color: AppColors.royalBlue,
                  backgroundColor: AppColors.aquaSoft,
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  insight,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDeep,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // View details → Link
              GestureDetector(
                onTap: () => context.push('/ai-assistant'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppColors.royalBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
