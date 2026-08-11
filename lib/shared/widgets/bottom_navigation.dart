import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../shared/models/user_session.dart';

class BottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleTap(BuildContext context, WidgetRef ref, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final baby = ref.read(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final isRestricted = isCaregiver || baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    switch (index) {
      case 0:
        GoRouter.of(context).go('/?tab=0');
        break;
      case 1:
        GoRouter.of(context).go('/?tab=1');
        break;
      case 2:
        if (isRestricted) {
          _showRestrictedAccessDialog(context, 'Health Analytics');
        } else {
          GoRouter.of(context).go('/predictive-health');
        }
        break;
      case 3:
        GoRouter.of(context).go('/music');
        break;
      case 4:
        if (isRestricted) {
          _showRestrictedAccessDialog(context, 'Nursery Shop');
        } else {
          GoRouter.of(context).go('/shop');
        }
        break;
    }
  }

  void _showRestrictedAccessDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You don\'t have permission to access $featureName.\n\nAs a Caregiver, your authorized access includes:\n• Live Video Monitoring\n• Live Sensor Telemetry\n• Alerts & Notifications\n• In-App Online Music',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final isRestricted = isCaregiver || baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.clayShadow,
        border: Border.all(
          color: AppColors.softTeal.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, ref, 0, Icons.home_rounded, 'Home'),
            _buildNavItem(context, ref, 1, Icons.videocam_outlined, 'Live'),
            _buildNavItem(context, ref, 2, Icons.favorite_rounded, 'Health', isLocked: isRestricted),
            _buildNavItem(context, ref, 3, Icons.music_note_rounded, 'Music'),
            if (!isRestricted) _buildNavItem(context, ref, 4, Icons.shopping_bag_outlined, 'Shop'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, int index, IconData icon, String label, {bool isLocked = false}) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _handleTap(context, ref, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: isSelected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          icon,
                          color: isLocked
                              ? AppColors.textMuted.withValues(alpha: 0.4)
                              : AppColors.textPrimary,
                          size: 22,
                        ),
                        if (isLocked)
                          const Positioned(
                            right: -5,
                            top: -3,
                            child: Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFFA726)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: isLocked
                            ? AppColors.textMuted.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
