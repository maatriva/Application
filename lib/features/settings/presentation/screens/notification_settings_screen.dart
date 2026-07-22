import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/profile/provider/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

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
          'Notification Settings',
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
              Text(
                'Instant Baby Telemetry Alerts',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Receive high-priority push notifications for physical events.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),

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
                      value: profile.cryAlerts,
                      title: 'Baby Cry Detection',
                      description:
                          'Alert me instantly if the camera detects crying sounds above 65dB.',
                      icon: Icons.face_retouching_natural_rounded,
                      iconBg: const Color(0xFFFDE8E8),
                      iconColor: const Color(0xFFE02424),
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .toggleNotificationPreference('cryAlerts');
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSwitchTile(
                      value: profile.abnormalHeartRateAlerts,
                      title: 'Heart Rate Anomalies',
                      description:
                          'High-priority notifications if the smart sock reports heart rates out of bound.',
                      icon: Icons.favorite_rounded,
                      iconBg: const Color(0xFFFCE8F3),
                      iconColor: const Color(0xFFE11D48),
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .toggleNotificationPreference(
                              'abnormalHeartRateAlerts',
                            );
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSwitchTile(
                      value: profile.tempAlerts,
                      title: 'Room & Body Temperature',
                      description:
                          'Alert me if baby skin temperature exceeds 38°C or if nursery is colder than 18°C.',
                      icon: Icons.thermostat_rounded,
                      iconBg: const Color(0xFFE1EFFE),
                      iconColor: const Color(0xFF1C64F2),
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .toggleNotificationPreference('tempAlerts');
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              Text(
                'Nursery & Care reminders',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Low-priority regular updates to help structure your day.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),

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
                      value: profile.feedingReminders,
                      title: 'Feeding Reminders',
                      description:
                          'Receive custom prompt guidelines every 3 hours to balance feeding schedules.',
                      icon: Icons.restaurant_rounded,
                      iconBg: const Color(0xFFEDFDF6),
                      iconColor: const Color(0xFF047857),
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .toggleNotificationPreference('feedingReminders');
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildSwitchTile(
                      value: profile.sleepAnalysisWeekly,
                      title: 'Weekly Sleep Reports',
                      description:
                          'Deliver comprehensive sleep rhythm analyses and AI optimization diagnostics.',
                      icon: Icons.nights_stay_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7E3AF2),
                      onChanged: (val) {
                        ref
                            .read(profileProvider.notifier)
                            .toggleNotificationPreference(
                              'sleepAnalysisWeekly',
                            );
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

  Widget _buildSwitchTile({
    required bool value,
    required String title,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20.r),
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
}
