import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../models/device_model.dart';

class DeviceOverviewCard extends StatelessWidget {
  final DeviceModel? cradleDevice;

  const DeviceOverviewCard({super.key, required this.cradleDevice});

  @override
  Widget build(BuildContext context) {
    final hasCradle = cradleDevice != null;
    final isConnected = hasCradle && cradleDevice!.isConnected;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8143D1), // Warm violet/purple
            Color(0xFF6E3DE0), // Rich primary purple
            Color(0xFF5322AC), // Deep lavender shadow
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E3DE0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative rings
          Positioned(
            right: -30.r,
            top: -30.r,
            child: Container(
              width: 140.r,
              height: 140.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 40.r,
            bottom: -50.r,
            child: Container(
              width: 160.r,
              height: 160.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(22.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.child_care_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'NURSERY CORE HUB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live pulsing indicator
                    if (isConnected)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF128054).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFFE2F3EC).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF34D399),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'LIVE SYNC',
                              style: TextStyle(
                                color: const Color(0xFFD1FAE5),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 18.h),

                // Device Name
                Text(
                  hasCradle ? cradleDevice!.name : 'Maatriva Smart Cradle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),

                // Subtitle description
                Text(
                  'Centralized telemetry, rocker & sensory analytics.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 20.h),
                Container(height: 1, color: Colors.white.withOpacity(0.12)),
                SizedBox(height: 16.h),

                // Metadata Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem(
                      label: 'STATUS',
                      value: hasCradle ? cradleDevice!.status : 'Disconnected',
                      valueColor: isConnected
                          ? const Color(0xFF34D399)
                          : Colors.redAccent,
                      isBoldValue: true,
                    ),
                    _buildMetaItem(
                      label: 'LAST SYNC',
                      value: hasCradle ? cradleDevice!.lastSynced : 'N/A',
                    ),
                    _buildMetaItem(
                      label: 'FIRMWARE',
                      value: hasCradle
                          ? cradleDevice!.firmwareVersion
                          : 'v1.2.4',
                    ),
                    _buildMetaItem(
                      label: 'DEVICE ID',
                      value: hasCradle ? cradleDevice!.deviceId : 'MTRV-001245',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String label,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 8.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 11.sp,
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
