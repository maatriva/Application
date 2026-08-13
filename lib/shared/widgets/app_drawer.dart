import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../shared/models/user_session.dart';
import '../../core/services/providers.dart';
import '../../features/profile/provider/profile_provider.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/music/widgets/admin_upload_dialog.dart';

/// Premium Maatriva Claymorphic Sidebar Navigation Drawer.
/// UI/UX Redesign matching Maatriva brand guidelines with preserved business logic.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E1FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bedroom_baby_rounded,
                    color: AppColors.royalBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'About Maatriva',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Beta)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maatriva is a premium, AI-powered smart baby monitoring ecosystem designed by pediatric specialists and IoT engineers. Our mission is to provide mothers and caregivers with clinical-grade, predictive health analytics and soothing automation to ensure every child sleeps safe and grows healthy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Sign Out?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppColors.navyDeep,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your MAATRIVA account?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final router = GoRouter.of(dialogContext);
                Navigator.of(dialogContext).pop();
                await ref.read(authNotifierProvider.notifier).logout();
                router.go(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRestrictedAccessDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access Restricted',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDeep,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You don\'t have permission to access $featureName.\n\nAs a Caregiver, your authorized access includes:\n• Live Video Monitoring\n• Live Sensor Telemetry\n• Alerts & Notifications\n• In-App Online Music',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Understood',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final caregiverName = profile.parentName.isNotEmpty ? profile.parentName : 'Caregiver';
    final caregiverEmail = profile.parentEmail.isNotEmpty ? profile.parentEmail : 'monitoring@maatriva.com';
    final caregiverAvatar = profile.parentAvatar.isNotEmpty
        ? profile.parentAvatar
        : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120';

    final authState = ref.watch(authNotifierProvider);
    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authState.session?.role == UserRole.caregiver ||
        baby?.accessLevel == 'LIVE_MONITOR_ONLY';
    final isAdmin = authState.session?.role == UserRole.admin ||
        authState.session?.email.toLowerCase() == 'admin@maatriva.com' ||
        caregiverEmail.toLowerCase() == 'admin@maatriva.com';

    final cacheService = ref.watch(cacheServiceProvider);
    final caregiverSession = cacheService.getCaregiverGrantedSession();
    final perms = (caregiverSession?['permissions'] as Map<String, dynamic>?) ?? {};
    final bool permsLiveMonitoring = !isCaregiver || (perms['live_monitoring'] == true);
    final bool permsCamera = !isCaregiver || (perms['camera_snapshot'] == true);
    final bool permsMusic = !isCaregiver || (perms['custom_music'] == true || perms['music'] == true);
    final bool permsAi = !isCaregiver || (perms['ai_assistant'] == true);
    final bool permsHealth = !isCaregiver || (perms['health_data'] == true);
    final bool permsNotifications = !isCaregiver || (perms['notifications'] == true);

    String currentLocation = '';
    try {
      currentLocation = GoRouterState.of(context).uri.toString();
    } catch (_) {}

    return Drawer(
      backgroundColor: const Color(0xFFEAF8F9),
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------------------------
            // 3. PROFILE HEADER DESIGN (Lavender/Purple Gradient Card)
            // -------------------------------------------------------------
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C5CEE), Color(0xFF9A7BFF), Color(0xFF647FEA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5CEE).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(caregiverAvatar),
                        ),
                      ),
                      // Soft decorative tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isCaregiver ? 'Caregiver' : 'Parent',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Hello,',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$caregiverName 💜',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCaregiver ? '$caregiverEmail (Caregiver Mode)' : caregiverEmail,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Scrollable Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  // ---------------------------------------------------------
                  // 5. QUICK ACTIONS SECTION
                  // ---------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                    child: Text(
                      '✨ QUICK ACTIONS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // 1. Live Sensors Dashboard
                  if (!isCaregiver || permsLiveMonitoring)
                    _buildDrawerCard(
                      context,
                      icon: Icons.sensors_rounded,
                      label: 'Live Sensors Dashboard',
                      iconBgColor: const Color(0xFFE2F8F0),
                      iconColor: const Color(0xFF00B894),
                      isActive: currentLocation == '/?tab=0' || currentLocation == '/',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/?tab=0');
                      },
                    ),

                  // 2. Live Video Feed
                  if (!isCaregiver || permsCamera)
                    _buildDrawerCard(
                      context,
                      icon: Icons.videocam_rounded,
                      label: 'Live Video Feed',
                      iconBgColor: const Color(0xFFE5F0FF),
                      iconColor: const Color(0xFF5478E8),
                      isActive: currentLocation == '/?tab=1',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/?tab=1');
                      },
                    ),

                  // 3. Alerts & Notifications
                  if (!isCaregiver || permsNotifications)
                    _buildDrawerCard(
                      context,
                      icon: Icons.notifications_rounded,
                      label: 'Alerts & Notifications',
                      iconBgColor: const Color(0xFFFFF0E5),
                      iconColor: const Color(0xFFFF7675),
                      isActive: currentLocation == '/notifications',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/notifications');
                      },
                    ),

                  // 4. Online Music Soother
                  if (!isCaregiver || permsMusic)
                    _buildDrawerCard(
                      context,
                      icon: Icons.music_note_rounded,
                      label: 'Online Music Soother',
                      iconBgColor: const Color(0xFFE8E1FF),
                      iconColor: const Color(0xFF6C5CE7),
                      isActive: currentLocation == '/music',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/music');
                      },
                    ),

                  // Admin Upload Option (if admin)
                  if (isAdmin)
                    _buildDrawerCard(
                      context,
                      icon: Icons.cloud_upload_rounded,
                      label: 'Admin: Upload Music & ZIP',
                      iconBgColor: const Color(0xFFE8E1FF),
                      iconColor: const Color(0xFF6C5CE7),
                      onTap: () {
                        Navigator.pop(context);
                        showAdminUploadDialog(context, ref);
                      },
                    ),

                  const SizedBox(height: 12),

                  // ---------------------------------------------------------
                  // 6. PARENT SECTION
                  // ---------------------------------------------------------
                  if (!isCaregiver) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                      child: Text(
                        '👥 PARENT SECTION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.royalBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    // 1. Profile
                    _buildDrawerCard(
                      context,
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      iconBgColor: const Color(0xFFE8E1FF),
                      iconColor: const Color(0xFF6C5CE7),
                      isActive: currentLocation == '/profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),

                    // 2. AI Assistant
                    _buildDrawerCard(
                      context,
                      icon: Icons.smart_toy_rounded,
                      label: 'AI Assistant',
                      iconBgColor: const Color(0xFFE5F0FF),
                      iconColor: const Color(0xFF5478E8),
                      isActive: currentLocation == '/ai-assistant',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/ai-assistant');
                      },
                    ),

                    // 3. Predictive Health
                    _buildDrawerCard(
                      context,
                      icon: Icons.favorite_rounded,
                      label: 'Predictive Health',
                      iconBgColor: const Color(0xFFFFF0E5),
                      iconColor: const Color(0xFFFF7675),
                      isActive: currentLocation == '/predictive-health',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/predictive-health');
                      },
                    ),

                    // 4. Caregiver Access
                    _buildDrawerCard(
                      context,
                      icon: Icons.supervisor_account_rounded,
                      label: 'Caregiver Access',
                      iconBgColor: const Color(0xFFE2F8F0),
                      iconColor: const Color(0xFF00B894),
                      isActive: currentLocation == AppRoutes.caregiverAccess || currentLocation == '/caregiver',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.caregiverAccess);
                      },
                    ),

                    // 5. Nursery Shop
                    _buildDrawerCard(
                      context,
                      icon: Icons.shopping_bag_rounded,
                      label: 'Nursery Shop',
                      iconBgColor: const Color(0xFFE5F0FF),
                      iconColor: const Color(0xFF5478E8),
                      isActive: currentLocation == '/shop',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/shop');
                      },
                    ),
                  ] else ...[
                    // Caregiver Granted Features Section
                    if (permsAi || permsHealth) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                        child: Text(
                          '⭐ AUTHORIZED FEATURES',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.royalBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (permsAi)
                        _buildDrawerCard(
                          context,
                          icon: Icons.smart_toy_rounded,
                          label: 'AI Assistant',
                          iconBgColor: const Color(0xFFE5F0FF),
                          iconColor: const Color(0xFF5478E8),
                          isActive: currentLocation == '/ai-assistant',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/ai-assistant');
                          },
                        ),
                      if (permsHealth)
                        _buildDrawerCard(
                          context,
                          icon: Icons.favorite_rounded,
                          label: 'Predictive Health',
                          iconBgColor: const Color(0xFFFFF0E5),
                          iconColor: const Color(0xFFFF7675),
                          isActive: currentLocation == '/predictive-health',
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/predictive-health');
                          },
                        ),
                    ],
                  ],

                  const SizedBox(height: 12),

                  // ---------------------------------------------------------
                  // INFORMATION & ACCOUNT SECTION
                  // ---------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                    child: Text(
                      'ℹ️ INFORMATION & ACCOUNT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  _buildDrawerCard(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    iconBgColor: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF5478E8),
                    onTap: () => _showAboutDialog(context),
                  ),

                  _buildDrawerCard(
                    context,
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    iconBgColor: const Color(0xFFFFEAEA),
                    iconColor: Colors.redAccent,
                    onTap: () => _showSignOutDialog(context, ref),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // -------------------------------------------------------------
            // FOOTER (Maatriva Branding & Version)
            // -------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                border: const Border(
                  top: BorderSide(color: Color(0xFFE4F0F2), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'MAATRIVA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Smart care for your little one 💜',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maatriva Smart Baby Monitor v1.0.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Claymorphic Menu Item Card Component
  Widget _buildDrawerCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconBgColor,
    required Color iconColor,
    bool isActive = false,
    bool isRestricted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFEEF3FF)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppColors.royalBlue.withValues(alpha: 0.5)
                    : const Color(0xFFE4F0F2),
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF183B70).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Pastel rounded icon container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isRestricted ? Colors.grey.shade100 : iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isRestricted ? Colors.grey.shade400 : iconColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                // Menu item label
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isRestricted
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : (isActive ? AppColors.royalBlue : AppColors.navyDeep),
                    ),
                  ),
                ),
                // Status badge or chevron arrow
                if (isRestricted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 10, color: Colors.orange),
                        const SizedBox(width: 3),
                        Text(
                          'Restricted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isActive
                        ? AppColors.royalBlue
                        : AppColors.navyDeep.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
