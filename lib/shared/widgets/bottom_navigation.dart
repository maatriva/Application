import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';

/// Premium Floating Claymorphic Bottom Navigation Bar.
/// Features 5 items:
/// 0. Home (🏠) -> /?tab=0
/// 1. Health (❤️) -> /predictive-health
/// 2. Live Monitor (📹 - Elevated Center Button) -> /?tab=1
/// 3. Music (🎵) -> /music
/// 4. Shop (🛍️) -> /shop
class BottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleTap(BuildContext context, WidgetRef ref, int index) {
    final authState = ref.read(authNotifierProvider);
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final cacheService = ref.read(cacheServiceProvider);
    final caregiverSession = cacheService.getCaregiverGrantedSession();
    final perms = (caregiverSession?['permissions'] as Map<String, dynamic>?) ?? {};

    bool isAllowed = true;
    String featureName = '';

    if (isCaregiver) {
      switch (index) {
        case 1: // Health
          if (perms['health_data'] != true) {
            isAllowed = false;
            featureName = 'Health Data & Predictive Analytics';
          }
          break;
        case 2: // Live Monitor
          if (perms['camera_snapshot'] != true && perms['live_monitoring'] != true) {
            isAllowed = false;
            featureName = 'Live Camera Feed';
          }
          break;
        case 3: // Music
          if (perms['custom_music'] != true && perms['music'] != true) {
            isAllowed = false;
            featureName = 'Music Controls';
          }
          break;
      }
    }

    if (!isAllowed) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Access Restricted: Your parent has not granted permission for $featureName.'),
          backgroundColor: const Color(0xFFE65100),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (onTap != null) {
      onTap!(index);
      return;
    }

    switch (index) {
      case 0:
        context.go('/?tab=0');
        break;
      case 1:
        context.go('/predictive-health');
        break;
      case 2:
        context.go('/?tab=1');
        break;
      case 3:
        context.go('/music');
        break;
      case 4:
        context.go('/shop');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.only(
          left: isNarrow ? 10 : 16,
          right: isNarrow ? 10 : 16,
          bottom: 12,
        ),
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Base Claymorphic Floating Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppColors.clayShadow,
                border: Border.all(
                  color: AppColors.softTeal.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, ref, 0, Icons.home_rounded, 'Home'),
                  _buildNavItem(context, ref, 1, Icons.favorite_rounded, 'Health'),
                  // Empty space slot for the elevated center Live Monitoring button
                  SizedBox(width: isNarrow ? 44 : 52),
                  _buildNavItem(context, ref, 3, Icons.music_note_rounded, 'Music'),
                  _buildNavItem(context, ref, 4, Icons.shopping_bag_rounded, 'Shop'),
                ],
              ),
            ),

            // Elevated Center Button: Live Monitoring 📹
            Positioned(
              top: -12,
              child: GestureDetector(
                onTap: () => _handleTap(context, ref, 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 5,
                            spreadRadius: -2,
                            offset: const Offset(-3, -3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live Monitor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: currentIndex == 2 ? AppColors.royalBlue : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _handleTap(context, ref, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.royalBlue : AppColors.navyDeep.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? AppColors.royalBlue : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
