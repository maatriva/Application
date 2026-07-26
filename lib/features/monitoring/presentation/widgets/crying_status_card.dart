import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';

class CryingStatusCard extends ConsumerWidget {
  const CryingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final telemetryMap = dashboardState.latestTelemetry;
    final cryVal = telemetryMap?['cry_detection']?.value;
    final isCrying = cryVal != null && cryVal > 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          // Speaker Icon in Emerald or Rose Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCrying ? const Color(0xFFFFEBEE) : const Color(0xFFE2F3EC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCrying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: isCrying ? const Color(0xFFD32F2F) : AppColors.sleepText,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Text labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Crying Status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCrying ? 'Baby is crying!' : 'Silent • Last checked just now',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isCrying ? const Color(0xFFD32F2F) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Capsule Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCrying ? const Color(0xFFFFEBEE) : const Color(0xFFF0EBFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCrying ? 'CRYING' : 'SILENT',
              style: TextStyle(
                color: isCrying ? const Color(0xFFC62828) : AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
