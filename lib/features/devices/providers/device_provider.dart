import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/providers.dart';
import '../../../../domain/repositories/device_repository.dart';
import '../../../../shared/models/client_device_info.dart';
import '../../../../shared/models/device_model.dart';
import '../models/activity_model.dart';

// Class to hold both devices and activity state
class DeviceState {
  final List<DeviceModel> devices;
  final List<ActivityModel> activities;
  final bool isScanning;
  final String? errorMessage;

  DeviceState({
    required this.devices,
    required this.activities,
    this.isScanning = false,
    this.errorMessage,
  });

  DeviceState copyWith({
    List<DeviceModel>? devices,
    List<ActivityModel>? activities,
    bool? isScanning,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceState(
      devices: devices ?? this.devices,
      activities: activities ?? this.activities,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceRepository _deviceRepo;

  DeviceNotifier({required DeviceRepository deviceRepo})
      : _deviceRepo = deviceRepo,
        super(DeviceState(devices: [], activities: [])) {
    loadDevices();
  }

  // Load Devices from repository
  Future<void> loadDevices() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final clientDevices = await _deviceRepo.getDevices();
      
      // Map domain/data ClientDeviceInfo to presentation DeviceModel
      final mappedDevices = clientDevices.map((d) {
        String description = 'Core IoT peripheral sensor';
        if (d.type == 'Smart Cradle') {
          description = 'Primary infant containment & sensory suite with automatic rocking.';
        } else if (d.type == 'ESP32 Controller') {
          description = 'Core low-latency telemetry processing unit aggregating sensor clusters.';
        } else if (d.type == 'Camera') {
          description = 'Wide-angle 4K infrared night-vision stream with micro-movement analysis.';
        }
        
        return DeviceModel(
          id: d.deviceId,
          name: d.deviceName,
          type: d.type,
          status: d.status == 'online' || d.status == 'ONLINE' || d.status == 'Connected' || d.status == 'PAIRED' ? 'Connected' : 'Offline',
          lastSynced: 'Just now',
          firmwareVersion: d.firmwareVersion,
          latestFirmwareVersion: d.firmwareVersion,
          deviceId: d.deviceId,
          serialNumber: 'SN-DEV-${d.deviceId.hashCode.abs()}',
          lastConnected: 'Today, Just now',
          batteryStatus: d.battery ?? -1,
          wifiSignal: 90,
          signalQuality: 'Excellent',
          description: description,
          hdReady: d.type == 'Camera',
          connectedNetwork: 'Maatriva_Nursery_5G',
          babyId: d.babyId,
        );
      }).toList();

      final initialActivities = [
        ActivityModel(
          id: 'act1',
          title: 'Device Connected',
          description: 'Camera successfully bound to secure RTSP profile.',
          timestamp: '15 min ago',
          icon: Icons.videocam_rounded,
          iconColor: const Color(0xFF6E3DE0),
        ),
        ActivityModel(
          id: 'act2',
          title: 'Firmware Checked',
          description: 'All modules scanned. ESP32 Controller is online.',
          timestamp: '1 hour ago',
          icon: Icons.system_update_rounded,
          iconColor: Colors.amber,
        ),
      ];

      state = DeviceState(
        devices: mappedDevices,
        activities: initialActivities,
        isScanning: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to load baby monitor devices. Please check your network and try again.',
      );
    }
  }

  // Toggles the connected state of a device
  void toggleDeviceStatus(String id) {
    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          final wasConnected = device.isConnected;
          final newStatus = wasConnected
              ? 'Offline'
              : (device.type == 'Camera' || device.type == 'Smart Cradle'
                    ? 'Connected'
                    : (device.type.contains('Controller')
                          ? 'Online'
                          : 'Active'));

          // Log activity
          final newAct = ActivityModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: wasConnected ? 'Device Disconnected' : 'Device Connected',
            description:
                '${device.name} has been ${wasConnected ? "shut down" : "activated and synchronized"}.',
            timestamp: 'Just now',
            icon: wasConnected
                ? Icons.power_off_rounded
                : Icons.check_circle_rounded,
            iconColor: wasConnected ? Colors.red : const Color(0xFF128054),
          );

          Future.microtask(() {
            _addActivity(newAct);
          });

          return device.copyWith(
            status: newStatus,
            lastSynced: wasConnected ? 'Offline' : 'Just now',
          );
        }
        return device;
      }).toList(),
    );
  }

  // Restart Device (Mock)
  Future<void> restartDevice(String id) async {
    // 1. Mark device as Offline
    DeviceModel? targetDevice;
    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          targetDevice = device;
          return device.copyWith(status: 'Offline', lastSynced: 'Rebooting...');
        }
        return device;
      }).toList(),
    );

    if (targetDevice == null) return;

    // Log restart started
    _addActivity(
      ActivityModel(
        id: 'restart_start_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sensor Restarted',
        description: 'Initiated remote hot reboot for ${targetDevice!.name}.',
        timestamp: 'Just now',
        icon: Icons.autorenew_rounded,
        iconColor: Colors.blue,
      ),
    );

    // 2. Wait 2 seconds and mark as connected/active again
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          final defaultStatus =
              (device.type == 'Camera' || device.type == 'Smart Cradle')
              ? 'Connected'
              : (device.type.contains('Controller') ? 'Online' : 'Active');
          return device.copyWith(status: defaultStatus, lastSynced: 'Just now');
        }
        return device;
      }).toList(),
    );

    _addActivity(
      ActivityModel(
        id: 'restart_success_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Device Online',
        description:
            '${targetDevice!.name} successfully rebooted and calibrated.',
        timestamp: 'Just now',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF128054),
      ),
    );
  }

  // Upgrade Firmware
  Future<void> upgradeFirmware(String id) async {
    DeviceModel? targetDevice;
    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          targetDevice = device;
          return device.copyWith(status: 'Offline', lastSynced: 'Upgrading...');
        }
        return device;
      }).toList(),
    );

    if (targetDevice == null) return;

    _addActivity(
      ActivityModel(
        id: 'fw_start_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Firmware Upgrading',
        description:
            'Installing firmware update to ${targetDevice!.latestFirmwareVersion} on ${targetDevice!.name}.',
        timestamp: 'Just now',
        icon: Icons.downloading_rounded,
        iconColor: Colors.amber,
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          final defaultStatus =
              (device.type == 'Camera' || device.type == 'Smart Cradle')
              ? 'Connected'
              : (device.type.contains('Controller') ? 'Online' : 'Active');
          return device.copyWith(
            status: defaultStatus,
            firmwareVersion: device.latestFirmwareVersion,
            lastSynced: 'Just now',
          );
        }
        return device;
      }).toList(),
    );

    _addActivity(
      ActivityModel(
        id: 'fw_success_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Firmware Updated',
        description:
            '${targetDevice!.name} successfully updated to firmware ${targetDevice!.latestFirmwareVersion}.',
        timestamp: 'Just now',
        icon: Icons.system_update_rounded,
        iconColor: const Color(0xFF128054),
      ),
    );
  }

  // Change Wi-Fi Network
  void changeWifi(String id, String ssid, int strength) {
    state = state.copyWith(
      devices: state.devices.map((device) {
        if (device.id == id) {
          final quality = strength > 80
              ? 'Excellent'
              : (strength > 50 ? 'Good' : 'Poor');

          _addActivity(
            ActivityModel(
              id: 'wifi_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Wi-Fi Changed',
              description:
                  '${device.name} network switched to "$ssid" (Signal: $strength%).',
              timestamp: 'Just now',
              icon: Icons.wifi_rounded,
              iconColor: Colors.purple,
            ),
          );

          return device.copyWith(
            connectedNetwork: ssid,
            wifiSignal: strength,
            signalQuality: quality,
          );
        }
        return device;
      }).toList(),
    );
  }

  // Connect new device
  Future<void> connectNewDevice(String deviceType) async {
    final randId = (state.devices.length + 1).toString();
    final deviceId = 'MTRV-00${1245 + state.devices.length}';
    final serial =
        'SN-${deviceType.substring(0, 3).toUpperCase()}-${334400 + state.devices.length * 11}';

    String name = deviceType;
    String desc = 'Add-on monitoring module integration.';
    String status = 'Connected';
    String? val;

    if (deviceType == 'Smart Sound Soother') {
      name = 'Sound Soother';
      desc =
          'Acoustic calming machine synchronizing bedtime lullabies & soundscapes.';
      status = 'Connected';
      val = 'Lullaby Active';
    } else if (deviceType == 'Smart Diaper Sensor') {
      name = 'Diaper Wetness Sensor';
      desc = 'Ultra-low power humidity core alert system.';
      status = 'Active';
      val = 'Dry';
    } else {
      name = 'Maatriva $deviceType';
      status = 'Active';
    }

    // Call Repository to pair
    await _deviceRepo.pairDevice(
      registrationKey: 'REG-$deviceId',
      babyId: 'baby_mock_123',
    );

    final newDevice = DeviceModel(
      id: randId,
      name: name,
      type: deviceType,
      status: status,
      lastSynced: 'Just now',
      firmwareVersion: 'v1.0.0',
      latestFirmwareVersion: 'v1.0.0',
      deviceId: deviceId,
      serialNumber: serial,
      lastConnected: 'Today, Just now',
      batteryStatus: 100,
      wifiSignal: 88,
      signalQuality: 'Good',
      description: desc,
      currentValue: val,
    );

    state = state.copyWith(devices: [...state.devices, newDevice]);

    _addActivity(
      ActivityModel(
        id: 'connect_$randId',
        title: 'Device Connected',
        description:
            'Newly paired $name successfully registered to infant hub cluster.',
        timestamp: 'Just now',
        icon: Icons.add_link_rounded,
        iconColor: const Color(0xFF6E3DE0),
      ),
    );
  }

  // Clear all devices (Empty state testing)
  void clearAllDevices() {
    state = state.copyWith(
      devices: [],
      activities: [
        ActivityModel(
          id: 'clear_${DateTime.now().millisecondsSinceEpoch}',
          title: 'All Devices Removed',
          description:
              'Telemetry profile was completely wiped from cloud storage.',
          timestamp: 'Just now',
          icon: Icons.delete_sweep_rounded,
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Future<void> restoreMockDevices() async {
    await loadDevices();
  }

  Future<ClientDeviceInfo> pairNewDevice({
    required String registrationKey,
    required String babyId,
  }) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final pairedDevice = await _deviceRepo.pairDevice(
        registrationKey: registrationKey,
        babyId: babyId,
      );
      await loadDevices();
      return pairedDevice;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> renameDevice(String deviceId, String newName) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      await _deviceRepo.renameDevice(deviceId, newName);
      await loadDevices();
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> reassignBaby(String deviceId, String babyId) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      await _deviceRepo.reassignBaby(deviceId, babyId);
      await loadDevices();
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> unpairDevice(String deviceId) async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      await _deviceRepo.unpairDevice(deviceId);
      await loadDevices();
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Internal helper to add activity log safely
  void _addActivity(ActivityModel act) {
    state = state.copyWith(activities: [act, ...state.activities]);
  }
}

final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return DeviceNotifier(deviceRepo: deviceRepo);
});
