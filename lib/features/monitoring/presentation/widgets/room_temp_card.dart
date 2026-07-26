import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';

class RoomTempCard extends ConsumerWidget {
  const RoomTempCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final telemetryMap = dashboardState.latestTelemetry;
    final tempVal = telemetryMap?['room_temperature']?.value;
    final tempText = tempVal != null ? '${tempVal.toStringAsFixed(1)}°C' : '22.4°C';

    // Normal recommended range is 20 - 22. Progress bar represents 15°C to 30°C.
    double progress = 0.65;
    if (tempVal != null) {
      progress = ((tempVal - 15.0) / 15.0).clamp(0.0, 1.0);
    }

    final isComfortable = tempVal == null || (tempVal >= 20.0 && tempVal <= 24.0);

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.ac_unit_rounded,
                color: isComfortable ? const Color(0xFF0F9D58) : const Color(0xFFD32F2F),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Room Temp',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tempText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              width: double.infinity,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComfortable ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
