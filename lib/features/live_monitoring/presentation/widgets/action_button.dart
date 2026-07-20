import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final BorderSide borderSide;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.borderSide,
    required this.onTap,
  });

  // Factory constructor for Record Button
  factory ActionButton.record({required VoidCallback onTap}) {
    return ActionButton(
      icon: Icons.videocam_outlined,
      label: 'Record',
      backgroundColor: const Color(0xFFF7F4FD),
      iconColor: AppColors.primary,
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.12),
        width: 1.5,
      ),
      onTap: onTap,
    );
  }

  // Factory constructor for Snapshot Button
  factory ActionButton.snapshot({required VoidCallback onTap}) {
    return ActionButton(
      icon: Icons.camera_alt_outlined,
      label: 'Snapshot',
      backgroundColor: const Color(0xFFF7F4FD),
      iconColor: AppColors.primary,
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.12),
        width: 1.5,
      ),
      onTap: onTap,
    );
  }

  // Factory constructor for Soothe Button
  factory ActionButton.soothe({required VoidCallback onTap}) {
    return ActionButton(
      icon: Icons.child_care_rounded,
      label: 'Soothe',
      backgroundColor: AppColors.connectBg,
      iconColor: AppColors.connectText,
      borderSide: const BorderSide(color: Colors.transparent),
      onTap: onTap,
    );
  }

  // Factory constructor for SOS Button
  factory ActionButton.sos({required VoidCallback onTap}) {
    return ActionButton(
      icon: Icons.emergency_rounded,
      label: 'SOS',
      backgroundColor: const Color(0xFFFFECEB),
      iconColor: const Color(0xFFE02424),
      borderSide: const BorderSide(color: Colors.transparent),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: borderSide.color == Colors.transparent
                  ? null
                  : Border.fromBorderSide(borderSide),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
