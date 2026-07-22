import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../providers/device_provider.dart';
import '../widgets/device_overview_card.dart';
import '../widgets/device_card.dart';
import '../widgets/diagnostics_section.dart';
import '../widgets/empty_state.dart';
import '../widgets/connect_device_bottom_sheet.dart';

class ConnectedDevicesScreen extends ConsumerWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceProvider);
    final notifier = ref.read(deviceProvider.notifier);

    // Find Smart Cradle for the Overview Card
    final cradle = state.devices.firstWhere(
      (d) => d.type == 'Smart Cradle',
      orElse: () =>
          state.devices.isNotEmpty ? state.devices.first : null as dynamic,
    );

    void showConnectBottomSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ConnectDeviceBottomSheet(
          onDeviceAdded: (deviceType) {
            notifier.connectNewDevice(deviceType);
          },
        ),
      );
    }

    void showSettingsMenu() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            children: [
              const Icon(Icons.settings_rounded, color: AppColors.primary),
              SizedBox(width: 10.w),
              const Text('Device Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsOption(
                icon: Icons.sync_rounded,
                title: 'Aggressive Telemetry polling',
                subtitle: 'Sync telemetry every 500ms',
                trailing: Switch(
                  value: true,
                  activeColor: AppColors.primary,
                  onChanged: (_) {},
                ),
              ),
              _buildSettingsOption(
                icon: Icons.wifi_tethering_rounded,
                title: 'Bluetooth High Range',
                subtitle: 'Increases antenna power output',
                trailing: Switch(
                  value: false,
                  activeColor: AppColors.primary,
                  onChanged: (_) {},
                ),
              ),
              _buildSettingsOption(
                icon: Icons.power_rounded,
                title: 'Clear telemetry logs',
                subtitle: 'Wipe mock list to test empty state',
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    notifier.clearAllDevices();
                  },
                  child: const Text(
                    'Wipe',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
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
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            onPressed: showSettingsMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulated pull-to-refresh: restore mock list if it's currently empty
            if (state.devices.isEmpty) {
              notifier.restoreMockDevices();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Nursery telemetry up to date!'),
                  backgroundColor: AppColors.sleepText,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            }
          },
          color: AppColors.primary,
          child: state.devices.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 40.h,
                  ),
                  child: Column(
                    children: [
                      EmptyStateWidget(
                        onConnectPressed: showConnectBottomSheet,
                      ),
                      SizedBox(height: 20.h),
                      TextButton(
                        onPressed: () => notifier.restoreMockDevices(),
                        child: const Text(
                          'Restore Default Mock Fleet',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Premium overview card
                      DeviceOverviewCard(cradleDevice: cradle),
                      SizedBox(height: 22.h),

                      // 2. Dynamic Diagnostics Grid
                      DiagnosticsSection(devices: state.devices),
                      SizedBox(height: 24.h),

                      // 3. Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Linked Hardware Suite',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.devices.length} Active',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // 4. Scrollable devices card list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.devices.length,
                        itemBuilder: (context, index) {
                          final device = state.devices[index];
                          return DeviceCard(
                            device: device,
                            onTap: () {
                              context.push(
                                '/profile/connected-devices/detail?id=${device.id}',
                              );
                            },
                            onToggle: (val) {
                              notifier.toggleDeviceStatus(device.id);
                            },
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // 5. Timeline Activities Section
                      _buildTimelineSection(state.activities),
                      SizedBox(height: 80.h), // Cushion for FAB
                    ],
                  ),
                ),
        ),
      ),
      // Floating Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showConnectBottomSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        icon: const Icon(Icons.add_link_rounded),
        label: Text(
          'Connect Device',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // Activity Log timeline builder
  Widget _buildTimelineSection(List<dynamic> activities) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Activity Timeline',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.04),
              width: 1.5,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5
                ? 5
                : activities.length, // Limit to recent 5 logs
            itemBuilder: (context, index) {
              final act = activities[index];
              final isLast =
                  index == (activities.length > 5 ? 4 : activities.length - 1);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dot and connector column
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: act.iconColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            act.icon,
                            color: act.iconColor,
                            size: 14.sp,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.w,
                              color: const Color(0xFFEFEAF5),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 14.w),

                    // Body text info
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  act.title,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  act.timestamp,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              act.description,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: Color(0xFFF3EDFA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
