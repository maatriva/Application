import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/activity_model.dart';

// Class to hold both devices and activity state
class DeviceState {
  final List<DeviceModel> devices;
  final List<ActivityModel> activities;
  final bool isScanning;

  DeviceState({
    required this.devices,
    required this.activities,
    this.isScanning = false,
  });

  DeviceState copyWith({
    List<DeviceModel>? devices,
    List<ActivityModel>? activities,
    bool? isScanning,
  }) {
    return DeviceState(
      devices: devices ?? this.devices,
      activities: activities ?? this.activities,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  DeviceNotifier() : super(DeviceState(devices: [], activities: [])) {
    restoreMockDevices();
  }

  // Initial Mock Data
  void restoreMockDevices() {
    final mockDevices = [
      DeviceModel(
        id: '1',
        name: 'Smart Cradle',
        type: 'Smart Cradle',
        status: 'Connected',
        lastSynced: 'Just now',
        firmwareVersion: 'v1.2.4',
        latestFirmwareVersion: 'v1.2.4',
        deviceId: 'MTRV-001245',
        serialNumber: 'SN-CRD-789012',
        lastConnected: 'Today, 20:54',
        batteryStatus: 88,
        wifiSignal: 92,
        signalQuality: 'Excellent',
        description:
            'Primary infant containment & sensory suite with automatic rocking.',
      ),
      DeviceModel(
        id: '2',
        name: 'ESP32 Controller',
        type: 'ESP32 Controller',
        status: 'Online',
        lastSynced: 'Just now',
        firmwareVersion: 'v2.0.1',
        latestFirmwareVersion: 'v2.0.5', // Update available
        deviceId: 'ESP32-948210',
        serialNumber: 'SN-ESP-554422',
        lastConnected: 'Today, 20:51',
        batteryStatus: -1, // Plugged in
        wifiSignal: 85,
        signalQuality: 'Good',
        description:
            'Core low-latency telemetry processing unit aggregating sensor clusters.',
      ),
      DeviceModel(
        id: '3',
        name: 'Camera',
        type: 'Camera',
        status: 'Connected',
        lastSynced: 'Just now',
        firmwareVersion: 'v3.1.2',
        latestFirmwareVersion: 'v3.1.2',
        deviceId: 'CAM-4K-01',
        serialNumber: 'SN-CAM-112233',
        lastConnected: 'Today, 20:55',
        batteryStatus: -1, // Plugged in
        wifiSignal: 95,
        signalQuality: 'Excellent',
        description:
            'Wide-angle 4K infrared night-vision stream with micro-movement analysis.',
        hdReady: true,
      ),
      DeviceModel(
        id: '4',
        name: 'Temperature Sensor',
        type: 'Temperature Sensor',
        status: 'Active',
        lastSynced: '2m ago',
        firmwareVersion: 'v1.0.8',
        latestFirmwareVersion: 'v1.0.8',
        deviceId: 'TEMP-SOCK-02',
        serialNumber: 'SN-TMP-998811',
        lastConnected: 'Today, 20:53',
        batteryStatus: 94,
        wifiSignal: 78,
        signalQuality: 'Good',
        description:
            'Infrared epidermal thermal sensor integrated into the smart sock.',
        currentValue: '36.8°C',
      ),
      DeviceModel(
        id: '5',
        name: 'Heart Rate Sensor',
        type: 'Heart Rate Sensor',
        status: 'Active',
        lastSynced: 'Just now',
        firmwareVersion: 'v1.1.0',
        latestFirmwareVersion: 'v1.1.0',
        deviceId: 'HR-SOCK-02',
        serialNumber: 'SN-HRT-887722',
        lastConnected: 'Today, 20:53',
        batteryStatus: 94,
        wifiSignal: 78,
        signalQuality: 'Good',
        description: 'Photoplethysmography core logging baby beats & SpO2.',
        currentValue: '122 BPM',
      ),
      DeviceModel(
        id: '6',
        name: 'Motion Sensor',
        type: 'Motion Sensor',
        status: 'Active',
        lastSynced: 'Just now',
        firmwareVersion: 'v1.0.2',
        latestFirmwareVersion: 'v1.0.2',
        deviceId: 'MOT-CRD-03',
        serialNumber: 'SN-MOT-334455',
        lastConnected: 'Today, 20:54',
        batteryStatus: 100,
        wifiSignal: 90,
        signalQuality: 'Excellent',
        description:
            'High-sensitivity 3-axis accelerometer detecting posture stirring.',
        currentValue: 'Quiet / Steady',
      ),
      DeviceModel(
        id: '7',
        name: 'Sleep Position Sensor',
        type: 'Sleep Position Sensor',
        status: 'Active',
        lastSynced: '1m ago',
        firmwareVersion: 'v1.0.5',
        latestFirmwareVersion: 'v1.0.5',
        deviceId: 'POS-CRD-04',
        serialNumber: 'SN-POS-221144',
        lastConnected: 'Today, 20:54',
        batteryStatus: 100,
        wifiSignal: 90,
        signalQuality: 'Excellent',
        description:
            'Computer Vision Posture AI parsing optimal sleeping orientations.',
        currentValue: 'Back (Supine)',
      ),
      DeviceModel(
        id: '8',
        name: 'Cry Detection Module',
        type: 'Cry Detection Module',
        status: 'Active',
        lastSynced: 'Just now',
        firmwareVersion: 'v2.1.0',
        latestFirmwareVersion: 'v2.1.0',
        deviceId: 'CRY-HUB-05',
        serialNumber: 'SN-CRY-776655',
        lastConnected: 'Today, 20:50',
        batteryStatus: -1, // Plugged in
        wifiSignal: 85,
        signalQuality: 'Good',
        description:
            'Acoustic pattern classifier listening for distress waveforms.',
        currentValue: 'Listening',
      ),
    ];

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
        description: 'All 8 modules scanned. ESP32 Controller has an update.',
        timestamp: '1 hour ago',
        icon: Icons.system_update_rounded,
        iconColor: Colors.amber,
      ),
      ActivityModel(
        id: 'act3',
        title: 'Sensor Restarted',
        description: 'Temperature Sensor calibrated & hot rebooted.',
        timestamp: '3 hours ago',
        icon: Icons.restart_alt_rounded,
        iconColor: Colors.blue,
      ),
    ];

    state = DeviceState(
      devices: mockDevices,
      activities: initialActivities,
      isScanning: false,
    );
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
  void connectNewDevice(String deviceType) {
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
        id: 'connect_${randId}',
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

  // Internal helper to add activity log safely
  void _addActivity(ActivityModel act) {
    state = state.copyWith(activities: [act, ...state.activities]);
  }
}

final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((
  ref,
) {
  return DeviceNotifier();
});
