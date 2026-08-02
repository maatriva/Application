import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../providers/device_provider.dart';
import '../widgets/wifi_section.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _isCheckingUpdate = false;
  bool _isRestarting = false;

  void _checkFirmware(DeviceModel device) async {
    setState(() {
      _isCheckingUpdate = true;
    });

    await Future.delayed(const Duration(seconds: 1500));

    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
    });

    if (device.hasFirmwareUpdate) {
      _showUpgradeConfirmDialog(device);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.sleepText,
                size: 24.r,
              ),
              SizedBox(width: 10.w),
              const Text('Up to Date'),
            ],
          ),
          content: Text(
            '${device.name} is running the latest firmware version (${device.firmwareVersion}).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showUpgradeConfirmDialog(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.amber, size: 24.r),
            SizedBox(width: 10.w),
            const Text('Update Available'),
          ],
        ),
        content: Text(
          'A new firmware update (${device.latestFirmwareVersion}) is available for ${device.name}. Update installation takes approximately 3 seconds and will temporarily reboot the module.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpgrade(device.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text(
              'Install Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performUpgrade(String id) async {
    ref.read(deviceProvider.notifier).upgradeFirmware(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Downloading firmware package...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _restartDevice(DeviceModel device) async {
    setState(() {
      _isRestarting = true;
    });

    ref.read(deviceProvider.notifier).restartDevice(device.id);

    // Close screen and return to list since the device is rebooting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reboot command sent to ${device.name}. Module is reconnecting...',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceProvider);
    final device = state.devices.firstWhere(
      (d) => d.id == widget.deviceId,
      orElse: () => DeviceModel(
        id: '',
        name: 'Unknown Device',
        type: '',
        status: 'Offline',
        lastSynced: '',
        firmwareVersion: '',
        latestFirmwareVersion: '',
        deviceId: '',
        serialNumber: '',
        lastConnected: '',
        batteryStatus: -1,
        wifiSignal: 0,
        signalQuality: '',
        description: '',
      ),
    );

    if (device.id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Device Details')),
        body: const Center(child: Text('Device not found or removed.')),
      );
    }

    final isConnected = device.isConnected;

    // Build specific hardware components diagnostics list
    List<Map<String, dynamic>> getHardwareChecklist() {
      switch (device.type) {
        case 'Camera':
          return [
            {'name': 'Image Sensor Resolution', 'status': '4K UHD', 'ok': true},
            {'name': 'Lens Focus Calibration', 'status': 'Stable', 'ok': true},
            {
              'name': 'Night Vision IR LED Array',
              'status': 'Standby',
              'ok': true,
            },
            {'name': 'Stream Latency', 'status': '112ms', 'ok': true},
          ];
        case 'Smart Cradle':
          return [
            {'name': 'Bilateral Electric Motor', 'status': 'Idle', 'ok': true},
            {'name': 'Safety Harness Sensor', 'status': 'Engaged', 'ok': true},
            {
              'name': 'Micro-Stirring Gyros',
              'status': 'Calibrated',
              'ok': true,
            },
            {'name': 'Brakes Lock', 'status': 'Active', 'ok': true},
          ];
        case 'Temperature Sensor':
          return [
            {'name': 'Epidermal IR Core', 'status': 'Active', 'ok': true},
            {'name': 'Power Adapter Input', 'status': '12V DC', 'ok': true},
            {'name': 'Bluetooth Sync Delay', 'status': '0.4s', 'ok': true},
          ];
        case 'Heart Rate Sensor':
          return [
            {'name': 'PPG Laser Emitters', 'status': 'Healthy', 'ok': true},
            {
              'name': 'Pulse Wave Integrator',
              'status': 'Operational',
              'ok': true,
            },
            {'name': 'SpO2 Oxygen Estimator', 'status': '98%', 'ok': true},
          ];
        case 'ESP32 Controller':
          return [
            {'name': 'SRAM Heap Memory', 'status': '182 KB Free', 'ok': true},
            {'name': 'Realtime CPU Load', 'status': '18%', 'ok': true},
            {'name': 'Hardware Interrupt Pins', 'status': 'Active', 'ok': true},
          ];
        default:
          return [
            {
              'name': 'Central Telemetry Watchdog',
              'status': 'Operational',
              'ok': true,
            },
            {'name': 'Local Cache Memory', 'status': 'Clear', 'ok': true},
            {'name': 'Power Regulator Gate', 'status': 'Stable', 'ok': true},
          ];
      }
    }

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          device.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Advanced developer tools unlocked for serial #${device.serialNumber}!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Device Info Header Card (Claymorphism Style)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.06),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    // Giant circular device icon
                    Container(
                      width: 70.r,
                      height: 70.r,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppColors.primaryLight.withOpacity(0.6)
                            : const Color(0xFFFDE8E8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        getDeviceIcon(),
                        color: isConnected ? AppColors.primary : Colors.red,
                        size: 32.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),

                    Text(
                      device.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? AppColors.sleepText
                                : Colors.red,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          device.status,
                          style: TextStyle(
                            color: isConnected
                                ? AppColors.sleepText
                                : Colors.red,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Container(height: 1, color: const Color(0xFFEFEAF5)),
                    SizedBox(height: 16.h),

                    // Hardware stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeaderStat(
                          label: 'FIRMWARE',
                          value: device.firmwareVersion,
                        ),
                        _buildHeaderStat(
                          label: 'POWER',
                          value: 'AC Power',
                        ),
                        _buildHeaderStat(
                          label: 'SIGNAL',
                          value: '${device.wifiSignal}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // 2. Wi-Fi Configuration Section
              WifiSection(
                device: device,
                onWifiChanged: (ssid, strength) {
                  ref
                      .read(deviceProvider.notifier)
                      .changeWifi(device.id, ssid, strength);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved Wi-Fi configuration!'),
                      backgroundColor: AppColors.sleepText,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),

              // 3. Firmware Update Card
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.06),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3EDFA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.system_update_rounded,
                                color: AppColors.healthText,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Firmware Engine',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Current: ${device.firmwareVersion}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (device.hasFirmwareUpdate)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'UPDATE READY',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STABLE VERSION',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                device.latestFirmwareVersion,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'RELEASE DATE',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'July 18, 2026',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Update CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isCheckingUpdate
                            ? null
                            : () => _checkFirmware(device),
                        style: TextButton.styleFrom(
                          foregroundColor: device.hasFirmwareUpdate
                              ? Colors.white
                              : AppColors.primary,
                          backgroundColor: device.hasFirmwareUpdate
                              ? Colors.amber.shade700
                              : AppColors.primaryLight.withOpacity(0.3),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isCheckingUpdate
                            ? SizedBox(
                                width: 14.r,
                                height: 14.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Text(
                                device.hasFirmwareUpdate
                                    ? 'Install Update'
                                    : 'Check for Updates',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // 4. Granular Diagnostics List
              Text(
                'Module Diagnostics',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.06),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.softShadow,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: getHardwareChecklist().length,
                  separatorBuilder: (context, index) =>
                      Container(height: 1, color: const Color(0xFFEFEAF5)),
                  itemBuilder: (context, index) {
                    final item = getHardwareChecklist()[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                item['status'],
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.sleepText,
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),

              // 5. Hardware Metadata Card (Serial, Last connected, ID)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8FD),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: const Color(0xFFEFEAF5)),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('SERIAL NUMBER', device.serialNumber),
                    SizedBox(height: 10.h),
                    _buildMetaRow('DEVICE ID', device.deviceId),
                    SizedBox(height: 10.h),
                    _buildMetaRow('LAST CONNECTED', device.lastConnected),
                    SizedBox(height: 10.h),
                    _buildMetaRow('SIGNAL QUALITY', device.signalQuality),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 6. Action buttons (Reboot / Reset)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRestarting
                          ? null
                          : () => _restartDevice(device),
                      icon: Icon(Icons.power_settings_new_rounded, size: 16.sp),
                      label: Text(
                        _isRestarting ? 'Sending reboot...' : 'Restart Device',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
