import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/colors.dart';
import '../../../dashboard/presentation/widgets/bottom_navigation.dart';
import '../../provider/profile_provider.dart';
import '../../../devices/providers/device_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final deviceState = ref.watch(deviceProvider);

    // Filter connected/active counts
    final activeDevicesCount = deviceState.devices
        .where((d) => d.isConnected)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Beautiful Gradient Hero Card with Profile Info
              _buildProfileHeader(context, profile),
              SizedBox(height: 16.h),

              // Interactive Stats Board (glassmorphism bento card row)
              _buildQuickStats(context, profile, activeDevicesCount),
              SizedBox(height: 24.h),

              // Menu List divided by visual groups
              _buildMenuSection(
                title: 'PERSONAL & FAMILY',
                items: [
                  _buildMenuTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Name, email, contact photo',
                    route: '/profile/edit',
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.family_restroom_rounded,
                    title: 'Parent & Partner Details',
                    subtitle: 'Spouse/partner, emergency contact',
                    route: '/profile/parent-details',
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.child_care_rounded,
                    title: "Baby's Profile Details",
                    subtitle: 'Name, DOB, gender, weight, height',
                    route: '/profile/baby-details',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildMenuSection(
                title: 'DEVICES & SHARING',
                items: [
                  _buildMenuTile(
                    context,
                    icon: Icons.router_rounded,
                    title: 'Connected Devices',
                    subtitle: 'Camera, Smart Sock status',
                    route: '/profile/connected-devices',
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Caregiver Access / QR Sharing',
                    subtitle: 'Manage guest caregiver tokens',
                    route: '/caregiver-access',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildMenuSection(
                title: 'HEALTH & PREFERENCES',
                items: [
                  _buildMenuTile(
                    context,
                    icon: Icons.medical_information_outlined,
                    title: 'Medical & Vaccine History',
                    subtitle: 'Immunization checklists, pediatrician',
                    route: '/profile/medical-history',
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Notification Preferences',
                    subtitle: 'Telemetry alarm thresholds',
                    route: '/profile/notifications',
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Privacy & Security',
                    subtitle: '2FA encryption, biometric login',
                    route: '/profile/privacy-security',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildMenuSection(
                title: 'SUPPORT & ACCOUNT',
                items: [
                  _buildMenuTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'FAQs, troubleshooting & live chat',
                    route: '/profile/help',
                  ),
                  _buildDestructiveTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Log out of current caregiver session',
                    onTap: () => _showSignOutDialog(context),
                  ),
                ],
              ),
              SizedBox(height: 100.h), // spacing above bottom bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            context.go('/?tab=0');
          } else if (index == 1) {
            context.go('/?tab=1');
          } else if (index == 2) {
            context.go('/predictive-health');
          } else if (index == 3) {
            context.go('/shop');
          }
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileState profile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20.r),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8A59FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 3.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36.r,
              backgroundImage: NetworkImage(profile.parentAvatar),
            ),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.parentName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile.parentEmail,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Primary Caregiver / Admin',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    ProfileState profile,
    int activeDevicesCount,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSingleStatCard(
              context,
              value: '1',
              label: 'Baby',
              icon: Icons.child_care_rounded,
              color: const Color(0xFFFDE8E8),
              iconColor: const Color(0xFFE02424),
              onTap: () => context.push('/profile/baby-details'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSingleStatCard(
              context,
              value: '$activeDevicesCount',
              label: 'IoT Online',
              icon: Icons.radar_rounded,
              color: const Color(0xFFEDFDF6),
              iconColor: const Color(0xFF03543F),
              onTap: () => context.push('/profile/connected-devices'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSingleStatCard(
              context,
              value: '2',
              label: 'Shared',
              icon: Icons.people_outline_rounded,
              color: const Color(0xFFE1EFFE),
              iconColor: const Color(0xFF1E40AF),
              onTap: () => context.push('/caregiver-access'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppColors.softShadow,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.04),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: AppColors.softShadow,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.03),
                width: 1,
              ),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(10.r),
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20.r),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5.sp, color: AppColors.textSecondary),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.r,
        color: AppColors.textSecondary.withOpacity(0.4),
      ),
      onTap: () {
        context.push(route);
      },
    );
  }

  Widget _buildDestructiveTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.redAccent, size: 20.r),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5.sp, color: AppColors.textSecondary),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.r,
        color: Colors.redAccent.withOpacity(0.4),
      ),
      onTap: onTap,
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: const Text(
            'Sign Out?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Are you sure you want to end your secure monitoring session on this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulating parent sign out...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
}
