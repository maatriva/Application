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
import '../../features/ai_monitoring/providers/ai_subscription_provider.dart';
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

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF5478E8), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Help & Support',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyDeep),
              ),
              const SizedBox(height: 12),
              Text(
                'Need assistance with your Maatriva Smart Monitor, IoT sensors, or caregiver permissions?\n\nContact our 24/7 Support Team:\n📧 support@maatriva.com\n📞 +1 (800) 555-MAATRIVA',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('OK', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2F8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF00B894), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyDeep),
              ),
              const SizedBox(height: 12),
              Text(
                'At Maatriva, your family\'s data security is our top priority. All live video streams and health telemetry data are end-to-end encrypted (E2EE) and processed strictly under HIPAA & GDPR guidelines.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFFFF7675), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Terms & Conditions',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyDeep),
              ),
              const SizedBox(height: 12),
              Text(
                'By using Maatriva Smart Baby Monitor, you agree to our Terms of Service. Maatriva provides intelligent monitoring and soothing features intended to assist parents and authorized caregivers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
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
            'You are not authorised to access this section.\n\nPlease ask the parent to enable access.',
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

    final perms = ref.watch(caregiverPermissionsProvider);
    final bool permsLiveVideo = !isCaregiver || (perms['live_video'] == true || perms['camera_snapshot'] == true);
    final bool permsHealth = !isCaregiver || (perms['health'] == true || perms['health_data'] == true);
    final bool permsAiMonitoring = !isCaregiver || (perms['ai_monitoring'] == true || perms['ai'] == true);
    final bool permsCustomParentFolder = !isCaregiver || (perms['custom_parent_folder'] == true || perms['custom_music'] == true);
    final bool permsShop = !isCaregiver || (perms['shop'] == true);
    final bool permsAlerts = !isCaregiver || (perms['real_time_alerts'] == true || perms['emergency_alerts'] == true);

    final isSubscribed = ref.watch(aiSubscriptionProvider).isSubscribed;
    final isParentSubscribed = !isCaregiver && isSubscribed;

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
                          border: Border.all(
                            color: isParentSubscribed ? const Color(0xFFD4AF37) : Colors.white,
                            width: isParentSubscribed ? 3.0 : 2.5,
                          ),
                          boxShadow: isParentSubscribed
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [
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
                  // 1. PARENT SECTION
                  // ---------------------------------------------------------
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

                  // 2. Caregiver Access
                  if (!isCaregiver)
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

                  // 3. Live Video
                  _buildDrawerCard(
                    context,
                    icon: Icons.videocam_rounded,
                    label: 'Live Video',
                    iconBgColor: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF5478E8),
                    isActive: currentLocation == '/' && !currentLocation.contains('tab=0'),
                    isRestricted: isCaregiver && !permsLiveVideo,
                    onTap: () {
                      if (isCaregiver && !permsLiveVideo) {
                        _showRestrictedAccessDialog(context, 'Live Video');
                      } else {
                        Navigator.pop(context);
                        context.go('/');
                      }
                    },
                  ),

                  // 4. Health
                  _buildDrawerCard(
                    context,
                    icon: Icons.favorite_rounded,
                    label: 'Health',
                    iconBgColor: const Color(0xFFFFF0E5),
                    iconColor: const Color(0xFFFF7675),
                    isActive: currentLocation == '/predictive-health',
                    isRestricted: isCaregiver && !permsHealth,
                    onTap: () {
                      if (isCaregiver && !permsHealth) {
                        _showRestrictedAccessDialog(context, 'Health');
                      } else {
                        Navigator.pop(context);
                        context.go('/predictive-health');
                      }
                    },
                  ),

                  // 5. Alerts & Notifications
                  _buildDrawerCard(
                    context,
                    icon: Icons.notifications_rounded,
                    label: 'Alerts & Notifications',
                    iconBgColor: const Color(0xFFFFF0E5),
                    iconColor: const Color(0xFFFF7675),
                    isActive: currentLocation == '/notifications',
                    isRestricted: isCaregiver && !permsAlerts,
                    onTap: () {
                      if (isCaregiver && !permsAlerts) {
                        _showRestrictedAccessDialog(context, 'Alerts & Notifications');
                      } else {
                        Navigator.pop(context);
                        context.push('/notifications');
                      }
                    },
                  ),

                  // 6. Shop
                  _buildDrawerCard(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Shop',
                    iconBgColor: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF5478E8),
                    isActive: currentLocation == '/shop',
                    isRestricted: isCaregiver && !permsShop,
                    onTap: () {
                      if (isCaregiver && !permsShop) {
                        _showRestrictedAccessDialog(context, 'Shop');
                      } else {
                        Navigator.pop(context);
                        context.go('/shop');
                      }
                    },
                  ),

                  // 7. AI Monitoring
                  _buildDrawerCard(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Monitoring',
                    iconBgColor: const Color(0xFFE2F8F0),
                    iconColor: const Color(0xFF00B894),
                    isActive: currentLocation.startsWith('/ai-monitoring') || currentLocation.startsWith('/ai-subscription'),
                    isRestricted: isCaregiver && !permsAiMonitoring,
                    onTap: () {
                      if (isCaregiver && !permsAiMonitoring) {
                        _showRestrictedAccessDialog(context, 'AI Monitoring');
                      } else {
                        Navigator.pop(context);
                        context.go('/ai-monitoring');
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // ---------------------------------------------------------
                  // 2. QUICK ACTIONS SECTION
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

                  // 8. Live Sensors Dashboard
                  _buildDrawerCard(
                    context,
                    icon: Icons.sensors_rounded,
                    label: 'Live Sensors Dashboard',
                    iconBgColor: const Color(0xFFE2F8F0),
                    iconColor: const Color(0xFF00B894),
                    isActive: currentLocation == '/?tab=0' || currentLocation == '/',
                    isRestricted: isCaregiver && !permsHealth,
                    onTap: () {
                      if (isCaregiver && !permsHealth) {
                        _showRestrictedAccessDialog(context, 'Live Sensors Dashboard');
                      } else {
                        Navigator.pop(context);
                        context.go('/?tab=0');
                      }
                    },
                  ),

                  // 9. Online Music Soother
                  _buildDrawerCard(
                    context,
                    icon: Icons.music_note_rounded,
                    label: 'Online Music Soother',
                    iconBgColor: const Color(0xFFE8E1FF),
                    iconColor: const Color(0xFF6C5CE7),
                    isActive: currentLocation == '/music',
                    isRestricted: isCaregiver && !permsCustomParentFolder,
                    onTap: () {
                      if (isCaregiver && !permsCustomParentFolder) {
                        _showRestrictedAccessDialog(context, 'Online Music Soother');
                      } else {
                        Navigator.pop(context);
                        context.go('/music');
                      }
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
                  // 3. INFORMATION & ACCOUNT SECTION
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

                  // 10. About Us
                  _buildDrawerCard(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    iconBgColor: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF5478E8),
                    onTap: () => _showAboutDialog(context),
                  ),

                  // 11. Help & Support
                  _buildDrawerCard(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    iconBgColor: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF5478E8),
                    onTap: () => _showHelpSupportDialog(context),
                  ),

                  // 12. Privacy Policy
                  _buildDrawerCard(
                    context,
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy Policy',
                    iconBgColor: const Color(0xFFE2F8F0),
                    iconColor: const Color(0xFF00B894),
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),

                  // 13. Terms & Conditions
                  _buildDrawerCard(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    iconBgColor: const Color(0xFFFFF0E5),
                    iconColor: const Color(0xFFFF7675),
                    onTap: () => _showTermsDialog(context),
                  ),

                  // 14. Sign Out
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
