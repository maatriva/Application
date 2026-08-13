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
/// 2. Live Monitor (📹) -> /?tab=1
/// 3. Music (🎵) -> /music
/// 4. Shop (🛍️) -> /shop
///
/// Dynamic Active State: Whichever tab is active dynamically rises from the navigation bar
/// with an elevated claymorphic container, gradient fill, and soft depth shadow.
class BottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  /// Resolves the active navigation index based on current route location and query params,
  /// preserving parent section highlighting during deep navigation.
  int _getEffectiveIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).matchedLocation;

      // Root / Home path check
      if (location == '/' || location.isEmpty) {
        final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
        if (tabStr == '1') return 2; // Live Monitor tab
        return 0; // Home tab
      }

      // Health section child routes
      if (location.startsWith('/predictive-health') ||
          location.startsWith('/health-reports') ||
          location.startsWith('/telemetry-history') ||
          location.startsWith('/wellness-monitoring') ||
          location.startsWith('/profile/medical-history')) {
        return 1;
      }

      // Music section child routes
      if (location.startsWith('/music')) {
        return 3;
      }

      // Shop section child routes
      if (location.startsWith('/shop')) {
        return 4;
      }
    } catch (_) {}

    // Fallback to passed currentIndex if valid and >= 0, else default to 0
    return currentIndex >= 0 ? currentIndex : 0;
  }

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
    final activeIndex = _getEffectiveIndex(context);
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppColors.clayShadow,
            border: Border.all(
              color: AppColors.softTeal.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, ref, activeIndex, 0, Icons.home_rounded, 'Home'),
              _buildNavItem(context, ref, activeIndex, 1, Icons.favorite_rounded, 'Health'),
              _buildNavItem(context, ref, activeIndex, 2, Icons.videocam_rounded, 'Live Monitor'),
              _buildNavItem(context, ref, activeIndex, 3, Icons.music_note_rounded, 'Music'),
              _buildNavItem(context, ref, activeIndex, 4, Icons.shopping_bag_rounded, 'Shop'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int activeIndex,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = activeIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(context, ref, index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: isSelected ? 48 : 36,
                height: isSelected ? 48 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: -1,
                            offset: const Offset(-2, -2),
                          ),
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.2)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : AppColors.navyDeep.withValues(alpha: 0.55),
                    size: isSelected ? 24 : 20,
                  ),
                ),
              ),
              SizedBox(height: isSelected ? 2 : 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isSelected ? 10 : 9.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.royalBlue : AppColors.textSecondary,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
