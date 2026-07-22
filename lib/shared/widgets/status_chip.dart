import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';

enum StatusType { dot, icon }

class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final StatusType type;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.type = StatusType.icon,
    this.onTap,
  });

  factory StatusChip.sleeping({VoidCallback? onTap}) {
    return StatusChip(
      label: 'Sleeping',
      backgroundColor: AppColors.sleepBg,
      textColor: AppColors.sleepText,
      type: StatusType.dot,
      onTap: onTap,
    );
  }

  factory StatusChip.healthy() {
    return const StatusChip(
      label: 'Healthy',
      icon: Icons.shield_outlined,
      backgroundColor: AppColors.healthBg,
      textColor: AppColors.healthText,
      type: StatusType.icon,
    );
  }

  factory StatusChip.connected() {
    return const StatusChip(
      label: 'Connected',
      icon: Icons.wifi,
      backgroundColor: AppColors.connectBg,
      textColor: AppColors.connectText,
      type: StatusType.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.12), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == StatusType.dot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
