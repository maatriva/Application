import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';

class HeartRateCard extends ConsumerWidget {
  const HeartRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final telemetryMap = dashboardState.latestTelemetry;
    final heartRateVal = telemetryMap?['heart_rate']?.value;
    final heartRateText = heartRateVal != null ? heartRateVal.toInt().toString() : '115';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Heart Icon and status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFD32F2F),
                size: 18,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  heartRateVal != null && (heartRateVal < 100 || heartRateVal > 150) ? 'ALERT' : 'STABLE',
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Heart Rate Value
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$heartRateText ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: 'BPM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mini bar chart (simulated waves)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(14),
                _buildBar(22),
                _buildBar(34),
                _buildBar(28),
                _buildBar(42),
                _buildBar(18),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Label
          const Center(
            child: Text(
              'Heart Rate',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
