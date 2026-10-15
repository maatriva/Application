import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../../ai_monitoring/providers/ai_subscription_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../shared/models/user_session.dart';
import '../providers/dashboard_provider.dart';

/// Clean welcoming app header with soft rounded claymorphic buttons,
/// notification bell with badge, and profile shortcut button.
class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final authSession = ref.watch(authNotifierProvider).session;
    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authSession?.role == UserRole.caregiver || baby?.accessLevel == 'LIVE_MONITOR_ONLY';
    final isSubscribed = ref.watch(aiSubscriptionProvider).isSubscribed;
    final isParentSubscribed = !isCaregiver && isSubscribed;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.clayShadow,
            border: Border.all(
              color: AppColors.softTeal.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Drawer menu button & Brand Logo
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.navyDeep,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.background,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/MaatrivaFavicon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MAATRIVA',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDeep,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (isParentSubscribed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            'AI+',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Notification & Profile buttons
              Row(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.navyDeep,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.navyDeep,
                      size: 22,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.background,
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
