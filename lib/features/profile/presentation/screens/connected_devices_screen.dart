import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/colors.dart';
import '../../provider/profile_provider.dart';

class ConnectedDevicesScreen extends ConsumerStatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  ConsumerState<ConnectedDevicesScreen> createState() =>
      _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState
    extends ConsumerState<ConnectedDevicesScreen> {
  bool _isScanning = false;
  String _scanStatusText = 'Searching for nearby Maatriva devices...';
  double _scanProgress = 0.0;
  Timer? _scanTimer;

  void _startDeviceScan() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatusText = 'Initializing Bluetooth scanner...';
    });

    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _scanProgress += 0.025;
        if (_scanProgress >= 0.3 && _scanProgress < 0.6) {
          _scanStatusText = 'Pinging 2.4GHz Smart Band channels...';
        } else if (_scanProgress >= 0.6 && _scanProgress < 0.9) {
          _scanStatusText = 'Found: Maatriva Sound Soother (A8:C9:10)...';
        } else if (_scanProgress >= 1.0) {
          timer.cancel();
          _isScanning = false;
          _showDevicePairingSuccessDialog();
        }
      });
    });
  }

  void _showDevicePairingSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.sleepText,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              const Text('Device Paired!'),
            ],
          ),
          content: const Text(
            'The Maatriva Sound Soother was successfully paired. It will now securely sync nursery sleep audio logs to your baby dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text(
                'Great',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Connected Devices',
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
                'Active Smart Monitoring Hardware',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Toggle status or add devices to continuous telemetry scans.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),

              // Devices List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.devices.length,
                itemBuilder: (context, index) {
                  final device = profile.devices[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: device.isConnected
                            ? AppColors.primary.withOpacity(0.06)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        // Device Icon Container
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: device.isConnected
                                ? AppColors.primaryLight
                                : AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getDeviceIcon(device.type),
                            color: device.isConnected
                                ? AppColors.primary
                                : AppColors.textSecondary.withOpacity(0.5),
                            size: 24.r,
                          ),
                        ),
                        SizedBox(width: 16.w),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Container(
                                    width: 8.r,
                                    height: 8.r,
                                    decoration: BoxDecoration(
                                      color: device.isConnected
                                          ? AppColors.sleepText
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    device.isConnected
                                        ? 'Online & Syncing'
                                        : 'Offline / Standby',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: device.isConnected
                                          ? AppColors.sleepText
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (device.batteryLevel != -1) ...[
                                    SizedBox(width: 12.w),
                                    Icon(
                                      Icons.battery_4_bar_rounded,
                                      size: 14.r,
                                      color: _getBatteryColor(
                                        device.batteryLevel,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      '${device.batteryLevel}%',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: _getBatteryColor(
                                          device.batteryLevel,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Toggle
                        Switch.adaptive(
                          value: device.isConnected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            ref
                                .read(profileProvider.notifier)
                                .toggleDeviceConnection(device.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),

              // Scanner / Addition Interface
              if (!_isScanning) ...[
                GestureDetector(
                  onTap: _startDeviceScan,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.12),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_to_queue_rounded,
                          color: AppColors.primary,
                          size: 36.r,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Pair New Smart Hardware',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Scan for nearby Bluetooth smart bands or baby socks.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Loading / Scanner Card
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              _scanStatusText,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      LinearProgressIndicator(
                        value: _scanProgress,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Camera':
        return Icons.videocam_rounded;
      case 'Smart Sock':
        return Icons.radar_rounded;
      case 'Hub':
        return Icons.router_rounded;
      default:
        return Icons.device_unknown_rounded;
    }
  }

  Color _getBatteryColor(int percentage) {
    if (percentage > 50) return AppColors.sleepText;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }
}
