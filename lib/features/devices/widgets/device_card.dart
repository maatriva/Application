import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../shared/models/models.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final String? assignedBabyName;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onOptionsTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.assignedBabyName,
    required this.onTap,
    this.onToggle,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = device.isConnected;

    // Icon selection
    IconData getDeviceIcon() {
      switch (device.type) {
        case 'Smart Cradle':
          return Icons.baby_changing_station_rounded;
        case 'ESP32 Controller':
          return Icons.memory_rounded;
        case 'Camera':
          return Icons.videocam_rounded;
        case 'Temperature Sensor':
          return Icons.thermostat_rounded;
        case 'Heart Rate Sensor':
          return Icons.favorite_rounded;
        case 'Motion Sensor':
          return Icons.directions_walk_rounded;
        case 'Sleep Position Sensor':
          return Icons.hotel_rounded;
        case 'Cry Detection Module':
          return Icons.hearing_rounded;
        default:
          return Icons.settings_remote_rounded;
      }
    }

    // Color theme based on device status
    Color getStatusColor() {
      if (!device.isConnected) return AppColors.textSecondary.withOpacity(0.4);
      switch (device.status) {
        case 'Connected':
        case 'Online':
        case 'Active':
          return AppColors.sleepText; // Green
        case 'Warning':
          return Colors.amber;
        default:
          return AppColors.sleepText;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isConnected
                ? AppColors.primary.withOpacity(0.08)
                : Colors.grey.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Icon container with soft purple/light accent
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.primaryLight.withOpacity(0.5)
                    : const Color(0xFFF3EDFA),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                getDeviceIcon(),
                color: isConnected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 14.w),

            // Middle info details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (device.type == 'Camera' && device.hdReady) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.connectBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '4K',
                            style: TextStyle(
                              color: AppColors.connectText,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      if (device.hasFirmwareUpdate) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'UPDATE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // Description or placeholder text
                  Text(
                    device.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (assignedBabyName != null && assignedBabyName!.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.child_care_rounded, size: 10.r, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          'Assigned to: $assignedBabyName',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 6.h),

                  // Status & Signal & Battery Indicators Row
                  Row(
                    children: [
                      // Circular status dot
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: getStatusColor(),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        device.status,
                        style: TextStyle(
                          color: getStatusColor(),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Values if present (BPM, temp, position, etc.)
                      if (isConnected && device.currentValue != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 3.r,
                          height: 3.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDCD6E5),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          device.currentValue!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],



                      // Wi-Fi Signal
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.wifi_rounded,
                        size: 11.sp,
                        color: device.wifiSignal > 75
                            ? AppColors.textSecondary
                            : (device.wifiSignal > 40
                                  ? Colors.orange
                                  : Colors.red),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${device.wifiSignal}%',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing toggle/switch, Chevron, or Options menu
            SizedBox(width: 12.w),
            if (onOptionsTap != null) ...[
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFFBEB4CD)),
                onPressed: onOptionsTap,
              ),
            ] else if (onToggle != null) ...[
              SizedBox(
                height: 30.h,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch.adaptive(
                    value: isConnected,
                    activeColor: AppColors.primary,
                    onChanged: onToggle,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFFBEB4CD),
                size: 14.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
