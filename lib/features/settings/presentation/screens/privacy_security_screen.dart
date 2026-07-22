import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/profile/provider/profile_provider.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge/Visual
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 40.r,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Your Data is Fully Encrypted',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Maatriva protects your video feeds using AES-256 standards.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              Text(
                'Security Access Settings',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      value: profile.twoFactorAuth,
                      title: 'Two-Factor Authentication (2FA)',
                      description:
                          'Require SMS or authenticator codes on secondary log-ins.',
                      icon: Icons.sms_outlined,
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .togglePrivacyPreference('twoFactorAuth');
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSwitchTile(
                      value: profile.biometricLogin,
                      title: 'Biometric Recognition',
                      description:
                          'Unlock baby monitoring panel using FaceID or fingerprints.',
                      icon: Icons.fingerprint_rounded,
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .togglePrivacyPreference('biometricLogin');
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              Text(
                'Health Records Sharing',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      value: profile.shareDataWithPediatrician,
                      title: 'Sync with Dr Evelyn Carter',
                      description:
                          'Authorize pediatrician to pull sleep duration and fever logs.',
                      icon: Icons.assignment_ind_outlined,
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .togglePrivacyPreference(
                              'shareDataWithPediatrician',
                            );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Export Data & Deletion Section
              Text(
                'Account Controls',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    _buildButtonTile(
                      title: 'Download My Personal Data',
                      description:
                          'Export all sleep cycles, video logs, and temperature diagnostics as CSV.',
                      icon: Icons.download_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Compiling secure zip backup... Email link will be sent to you in 3 minutes.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildButtonTile(
                      title: 'Request Account Deletion',
                      description:
                          'Permanently remove credentials, paired camera files, and telemetry metrics.',
                      icon: Icons.delete_forever_rounded,
                      color: Colors.redAccent,
                      onTap: () {
                        _showDeleteConfirmation(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This action is irreversible. All camera pair records, bio-metric histories, and shared family access authorizations will be permanently deleted.',
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
                    content: Text('Simulating account deletion...'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required bool value,
    required String title,
    required String description,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }
}
