import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import 'package:maatriva/shared/models/models.dart';
import 'package:maatriva/shared/models/baby_profile.dart';
import '../../provider/profile_provider.dart';
import '../../../devices/providers/device_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/services/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final deviceState = ref.watch(deviceProvider);

    // Filter connected smart cradles
    final smartCradles = deviceState.devices
        .where((d) => d.type.toLowerCase() == 'smart cradle')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Caregiver Profile',
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              // 1. Profile Details Card
              _buildCaregiverDetailsCard(context, profile),
              SizedBox(height: 16.h),

              // 2. Registered Babies Section
              _buildRegisteredBabiesCard(context, ref),
              SizedBox(height: 16.h),

              // 3. Smart Cradle Section
              _buildSmartCradleCard(context, smartCradles),
              SizedBox(height: 16.h),

              // 4. App Info & Sign Out
              _buildAppInfoAndSignOutCard(context, ref),
              SizedBox(height: 24.h),
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

  Widget _buildCaregiverDetailsCard(BuildContext context, ProfileState profile) {
    final relationship = profile.relationship.isNotEmpty ? profile.relationship : 'Caregiver';
    final parentAvatarUrl = profile.parentAvatar.isNotEmpty
        ? profile.parentAvatar
        : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=256';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 3.r,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36.r,
                  backgroundImage: NetworkImage(parentAvatarUrl),
                  backgroundColor: AppColors.primaryLight,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.parentName.isNotEmpty ? profile.parentName : 'No Name Set',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        relationship,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(height: 1, color: Color(0xFFF5F3FB)),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.email_outlined, 'Email Address', profile.parentEmail),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.phone_android_outlined, 'Phone Number', profile.parentPhone.isNotEmpty ? profile.parentPhone : 'Not Provided'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.family_restroom_rounded, 'Relationship', relationship),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.textSecondary.withOpacity(0.6)),
        SizedBox(width: 12.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredBabiesCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.child_care_rounded, color: AppColors.primary, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Registered Babies',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          FutureBuilder<List<BabyProfile>>(
            future: ref.read(babyRepositoryProvider).getBabies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    'No babies registered yet.',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                  ),
                );
              }

              final babies = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: babies.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final baby = babies[index];
                  final babyAge = _calculateAge(baby.birthDate);
                  final babyAvatarUrl = baby.photoUrl != null && baby.photoUrl!.isNotEmpty
                      ? baby.photoUrl!
                      : 'https://images.unsplash.com/photo-1519689680058-324335c77ebf?auto=format&fit=crop&q=80&w=256';

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundImage: NetworkImage(babyAvatarUrl),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              baby.name,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${baby.gender.toUpperCase()} • $babyAge',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCradleCard(BuildContext context, List<dynamic> cradles) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.router_rounded, color: AppColors.primary, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'Connected Smart Cradle(s)',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (cradles.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No paired smart cradle found.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cradles.length,
              separatorBuilder: (_, __) => Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(height: 1, color: Color(0xFFF5F3FB)),
              ),
              itemBuilder: (context, index) {
                final cradle = cradles[index];
                final isConnected = cradle.status == 'Connected' || cradle.status == 'Online';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceDetailRow('Device Name', cradle.name),
                    SizedBox(height: 8.h),
                    _buildDeviceDetailRow('Device ID', cradle.deviceId),
                    SizedBox(height: 8.h),
                    _buildDeviceDetailRow('Firmware Version', cradle.firmwareVersion),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Connection Status',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            isConnected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildDeviceDetailRow('Last Connected', cradle.lastConnected ?? 'Just now'),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoAndSignOutCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'App Version',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              Text(
                'MAATRIVA v1.0.0',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(height: 1, color: Color(0xFFF5F3FB)),
          SizedBox(height: 16.h),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            subtitle: Text(
              'End secure monitoring session',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.r,
              color: Colors.redAccent.withOpacity(0.4),
            ),
            onTap: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
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
            'Are you sure you want to sign out of your MAATRIVA account?',
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
                ref.read(authNotifierProvider.notifier).logout();
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

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final months = (difference.inDays / 30.4).floor();
    if (months < 1) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks old';
    }
    if (months >= 12) {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year' + (years > 1 ? 's' : '') + ' old';
      }
      return '$years yr $remainingMonths mo old';
    }
    return '$months months old';
  }
}
