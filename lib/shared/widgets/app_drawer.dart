import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../shared/models/user_session.dart';
import '../../features/profile/provider/profile_provider.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/music/widgets/admin_upload_dialog.dart';

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
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.baby_changing_station_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'About Maatriva',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Beta)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maatriva is a premium, AI-powered smart baby monitoring ecosystem designed by pediatric specialists and IoT engineers. Our mission is to provide mothers and caregivers with clinical-grade, predictive health analytics and soothing automation to ensure every child sleeps safe and grows healthy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Close'),
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
          title: const Text(
            'Sign Out?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your MAATRIVA account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Sign Out'),
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
              child: const Text('Understood'),
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

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF8A59FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(32)),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(caregiverAvatar),
              ),
            ),
            accountName: Text(
              caregiverName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              isCaregiver ? '$caregiverEmail (Caregiver Mode)' : caregiverEmail,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),

          // Drawer items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    isCaregiver ? 'CAREGIVER PERMITTED ACTIONS' : 'QUICK ACTIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Permitted for Caregiver: Live Sensors & Monitoring
                _buildDrawerTile(
                  context,
                  icon: Icons.sensors_rounded,
                  label: 'Live Sensors Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/?tab=0');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.videocam_outlined,
                  label: 'Live Video Feed',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/?tab=1');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.notifications_outlined,
                  label: 'Alerts & Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/notifications');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.music_note_outlined,
                  label: 'Online Music Soother',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/music');
                  },
                ),
                if (isAdmin)
                  _buildDrawerTile(
                    context,
                    icon: Icons.cloud_upload_rounded,
                    label: 'Admin: Upload Music & ZIP',
                    iconColor: const Color(0xFF6C5CE7),
                    onTap: () {
                      Navigator.pop(context);
                      showAdminUploadDialog(context, ref);
                    },
                  ),

                const Divider(height: 24, color: AppColors.divider),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'PARENT SECTIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                _buildDrawerTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'Profile Settings');
                      return;
                    }
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Assistant',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'AI Assistant');
                      return;
                    }
                    Navigator.pop(context);
                    context.push('/ai-assistant');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.favorite_border_rounded,
                  label: 'Predictive Health',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'Predictive Health Analytics');
                      return;
                    }
                    Navigator.pop(context);
                    context.go('/predictive-health');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.share_rounded,
                  label: 'Caregiver Access',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'Caregiver Access Management');
                      return;
                    }
                    Navigator.pop(context);
                    context.push('/caregiver-access');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Nursery Shop',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'Nursery Shop');
                      return;
                    }
                    Navigator.pop(context);
                    context.go('/shop');
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Join Shared Baby (Scan QR)',
                  isRestricted: isCaregiver,
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'QR Registration');
                      return;
                    }
                    Navigator.pop(context);
                    final authState = ref.read(authNotifierProvider);
                    if (authState.status != AuthStatus.authenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Authentication required. Please log in / authorize first to scan QR code.')),
                      );
                      context.push('/login');
                    } else {
                      context.push('/join-shared-baby');
                    }
                  },
                ),

                const Divider(height: 24, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'INFORMATION & ACCOUNT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About Us',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  iconColor: Colors.redAccent,
                  labelColor: Colors.redAccent,
                  onTap: () => _showSignOutDialog(context, ref),
                ),
              ],
            ),
          ),

          // Version footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Maatriva Smart Baby Monitor v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    bool isRestricted = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isRestricted
            ? AppColors.textSecondary.withOpacity(0.4)
            : (iconColor ?? AppColors.primary),
        size: 22,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isRestricted
                    ? AppColors.textSecondary.withOpacity(0.6)
                    : (labelColor ?? AppColors.textPrimary),
              ),
            ),
          ),
          if (isRestricted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 10, color: Colors.orange),
                  const SizedBox(width: 3),
                  Text(
                    'Restricted',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      dense: true,
    );
  }
}
