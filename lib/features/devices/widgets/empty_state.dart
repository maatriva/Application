import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maatriva/core/theme/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onConnectPressed;

  const EmptyStateWidget({super.key, required this.onConnectPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant layered visual stack instead of a raw picture
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110.r,
                height: 110.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(Icons.router_rounded, color: AppColors.primary, size: 42.sp),
              Positioned(
                bottom: 8.r,
                right: 8.r,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Colors.red.shade400,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          Text(
            'No Devices Connected',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            'All smart baby cuffs, thermal socks, 4K cameras, and rocking controllers have been unlinked. Connect your hardware suite to resume real-time AI vitals stream.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 28.h),

          ElevatedButton.icon(
            onPressed: onConnectPressed,
            icon: Icon(Icons.add_link_rounded, size: 16.sp),
            label: const Text('Connect Baby Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              textStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
