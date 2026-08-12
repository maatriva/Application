import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../../shared/models/baby_profile.dart';
import '../../../../shared/models/device_model.dart';
import '../../../../core/services/providers.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/device_overview_card.dart';
import '../widgets/device_card.dart';
import '../widgets/diagnostics_section.dart';
import '../widgets/empty_state.dart';

class ConnectedDevicesScreen extends ConsumerStatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  ConsumerState<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends ConsumerState<ConnectedDevicesScreen> {
  List<BabyProfile> _babies = [];
  bool _loadingBabies = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    try {
      final babyRepo = ref.read(babyRepositoryProvider);
      final list = await babyRepo.getBabies();
      if (mounted) {
        setState(() {
          _babies = list;
          _loadingBabies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingBabies = false;
        });
      }
    }
  }

  void _navigateToPairing() {
    context.push('/profile/connected-devices/pair');
  }

  void _showDeviceOptions(dynamic device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCD6E5),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                device.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ID: ${device.deviceId}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              const Divider(height: 24, color: Color(0xFFEFEAF5)),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                title: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile/connected-devices/detail?id=${device.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Rename Device', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(device);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                title: const Text('Assign to another Baby', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showReassignDialog(device);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                title: const Text('Unpair Device', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showUnpairConfirm(device);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(dynamic device) {
    final controller = TextEditingController(text: device.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: const Text('Rename Device', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Enter new name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                Navigator.pop(context);
                setState(() => _isProcessing = true);
                try {
                  await ref.read(deviceProvider.notifier).renameDevice(device.deviceId, newName);
                  await ref.read(dashboardProvider.notifier).refresh();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Rename', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showReassignDialog(dynamic device) {
    BabyProfile? selected = _babies.firstWhere((b) => b.id == device.babyId, orElse: () => _babies.first);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: const Text('Assign to Baby', style: TextStyle(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<BabyProfile>(
            value: selected,
            items: _babies.map((b) {
              return DropdownMenuItem<BabyProfile>(
                value: b,
                child: Text(b.name),
              );
            }).toList(),
            onChanged: (val) {
              selected = val;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected == null) return;
                Navigator.pop(context);
                setState(() => _isProcessing = true);
                try {
                  await ref.read(deviceProvider.notifier).reassignBaby(device.deviceId, selected!.id);
                  await ref.read(dashboardProvider.notifier).refresh();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reassign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUnpairConfirm(dynamic device) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: const Text('Unpair Device', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to unpair ${device.name}? This will stop telemetry integration.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isProcessing = true);
                try {
                  await ref.read(deviceProvider.notifier).unpairDevice(device.deviceId);
                  await ref.read(dashboardProvider.notifier).refresh();
                } catch (e) {
                  _showErrorSnackBar(e.toString());
                } finally {
                  setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Unpair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.replaceAll('ApiException:', '').trim()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardDevice = ref.watch(dashboardProvider.select((s) => s.device));
    final state = ref.watch(deviceProvider);
    
    // Filter to include ONLY the logged-in registered cradle information
    final userDevices = state.devices.where((d) {
      if (dashboardDevice != null && dashboardDevice.deviceId.isNotEmpty) {
        return d.deviceId == dashboardDevice.deviceId || d.id == dashboardDevice.deviceId;
      }
      return d.type == 'Smart Cradle';
    }).toList();

    // If list empty but dashboard device present, create single device list
    final devices = userDevices.isNotEmpty
        ? userDevices
        : (dashboardDevice != null
            ? [
                DeviceModel(
                  id: dashboardDevice.deviceId,
                  name: dashboardDevice.deviceName.isNotEmpty ? dashboardDevice.deviceName : 'Smart Cradle',
                  type: 'Smart Cradle',
                  status: (dashboardDevice.status == 'online' || dashboardDevice.status == 'ONLINE' || dashboardDevice.status == 'Connected' || dashboardDevice.status == 'PAIRED') ? 'Connected' : 'Offline',
                  lastSynced: 'Just now',
                  firmwareVersion: dashboardDevice.firmwareVersion,
                  latestFirmwareVersion: dashboardDevice.firmwareVersion,
                  deviceId: dashboardDevice.deviceId,
                  serialNumber: 'SN-DEV-${dashboardDevice.deviceId.hashCode.abs()}',
                  lastConnected: 'Today, Just now',
                  batteryStatus: -1,
                  wifiSignal: 90,
                  signalQuality: 'Excellent',
                  description: 'Primary infant containment & sensory suite with automatic rocking.',
                  hdReady: false,
                  connectedNetwork: 'Maatriva_Nursery_5G',
                  babyId: dashboardDevice.babyId,
                )
              ]
            : <DeviceModel>[]);

    final cradle = devices.isNotEmpty ? devices.first : null;

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
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(deviceProvider.notifier).loadDevices();
                await _loadBabies();
              },
              color: AppColors.primary,
              child: devices.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                      child: EmptyStateWidget(
                        onConnectPressed: _navigateToPairing,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Premium overview card
                          DeviceOverviewCard(cradleDevice: cradle),
                          SizedBox(height: 22.h),

                          // 2. Dynamic Diagnostics Grid
                          DiagnosticsSection(devices: devices),
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
                                '${devices.length} Active',
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
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final assignedBabyName = _babies
                                  .firstWhere((b) => b.id == device.babyId,
                                      orElse: () => BabyProfile(id: '', parentId: '', name: '', birthDate: DateTime.now(), gender: ''))
                                  .name;
                              
                              return DeviceCard(
                                device: device,
                                assignedBabyName: assignedBabyName,
                                onTap: () {
                                  context.push(
                                    '/profile/connected-devices/detail?id=${device.id}',
                                  );
                                },
                                onOptionsTap: () => _showDeviceOptions(device),
                              );
                            },
                          ),
                          SizedBox(height: 80.h), // Cushion for FAB
                        ],
                      ),
                    ),
            ),
            if (_isProcessing || state.isScanning || _loadingBabies)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToPairing,
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
}
