import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/colors.dart';
import '../models/device_model.dart';

class DiagnosticsSection extends StatelessWidget {
  final List<DeviceModel> devices;

  const DiagnosticsSection({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate statuses based on devices list

    // 1. Camera Status
    final camera = devices.firstWhere(
      (d) => d.type == 'Camera',
      orElse: () => DeviceModel(
        id: '',
        name: '',
        type: 'Camera',
        status: 'Offline',
        lastSynced: '',
        firmwareVersion: '',
        latestFirmwareVersion: '',
        deviceId: '',
        serialNumber: '',
        lastConnected: '',
        batteryStatus: -1,
        wifiSignal: 0,
        signalQuality: 'Poor',
        description: '',
      ),
    );
    final cameraHealth = camera.id.isEmpty
        ? 'offline'
        : (camera.isConnected ? 'healthy' : 'offline');

    // 2. Sensors Status
    final sensorDevices = devices
        .where((d) => d.type.contains('Sensor') || d.type.contains('Cradle'))
        .toList();
    final totalSensors = sensorDevices.length;
    final activeSensors = sensorDevices.where((d) => d.isConnected).length;

    String sensorsHealth = 'offline';
    if (totalSensors > 0) {
      if (activeSensors == totalSensors) {
        sensorsHealth = 'healthy';
      } else if (activeSensors > 0) {
        sensorsHealth = 'warning';
      } else {
        sensorsHealth = 'offline';
      }
    }

    // 3. Internet Status
    final activeConnectedWifi = devices
        .where((d) => d.isConnected && d.wifiSignal > 0)
        .toList();
    String internetHealth = 'offline';
    if (activeConnectedWifi.isNotEmpty) {
      final avgSignal =
          activeConnectedWifi.map((d) => d.wifiSignal).reduce((a, b) => a + b) /
          activeConnectedWifi.length;
      if (avgSignal > 75) {
        internetHealth = 'healthy';
      } else if (avgSignal > 40) {
        internetHealth = 'warning';
      } else {
        internetHealth = 'offline';
      }
    }

    // 4. ESP32 Controller
    final esp32 = devices.firstWhere(
      (d) => d.type.contains('ESP32'),
      orElse: () => DeviceModel(
        id: '',
        name: '',
        type: 'ESP32 Controller',
        status: 'Offline',
        lastSynced: '',
        firmwareVersion: '',
        latestFirmwareVersion: '',
        deviceId: '',
        serialNumber: '',
        lastConnected: '',
        batteryStatus: -1,
        wifiSignal: 0,
        signalQuality: 'Poor',
        description: '',
      ),
    );
    final espHealth = esp32.id.isEmpty
        ? 'offline'
        : (esp32.isConnected ? 'healthy' : 'offline');

    // 5. Battery Status
    final batteryDevices = devices.where((d) => d.batteryStatus != -1).toList();
    String batteryHealth = 'healthy';
    if (batteryDevices.isNotEmpty) {
      final lowestBattery = batteryDevices
          .map((d) => d.batteryStatus)
          .reduce((a, b) => a < b ? a : b);
      if (lowestBattery > 35) {
        batteryHealth = 'healthy';
      } else if (lowestBattery > 15) {
        batteryHealth = 'warning';
      } else {
        batteryHealth = 'offline';
      }
    }

    // 6. Storage Status
    const storageHealth = 'healthy'; // Mocked as healthy by default

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System Diagnostics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Live Telemetry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // 2x3 Grid of Diagnostic Cards
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.r,
          crossAxisSpacing: 10.r,
          childAspectRatio: 1.0,
          children: [
            _buildDiagnosticCard(
              title: 'Camera',
              status: cameraHealth,
              icon: Icons.videocam_rounded,
            ),
            _buildDiagnosticCard(
              title: 'Sensors',
              status: sensorsHealth,
              icon: Icons.sensors_rounded,
            ),
            _buildDiagnosticCard(
              title: 'Internet',
              status: internetHealth,
              icon: Icons.language_rounded,
            ),
            _buildDiagnosticCard(
              title: 'ESP32',
              status: espHealth,
              icon: Icons.memory_rounded,
            ),
            _buildDiagnosticCard(
              title: 'Battery',
              status: batteryHealth,
              icon: Icons.battery_charging_full_rounded,
            ),
            _buildDiagnosticCard(
              title: 'Storage',
              status: storageHealth,
              icon: Icons.sd_storage_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosticCard({
    required String title,
    required String status,
    required IconData icon,
  }) {
    Color getThemeColor() {
      switch (status) {
        case 'healthy':
          return const Color(0xFF128054);
        case 'warning':
          return Colors.orange.shade700;
        case 'offline':
        default:
          return Colors.red.shade700;
      }
    }

    Color getBgColor() {
      switch (status) {
        case 'healthy':
          return const Color(0xFFE2F3EC);
        case 'warning':
          return const Color(0xFFFFF3E0);
        case 'offline':
        default:
          return const Color(0xFFFDE8E8);
      }
    }

    String getStatusText() {
      switch (status) {
        case 'healthy':
          return 'Healthy';
        case 'warning':
          return 'Warning';
        case 'offline':
        default:
          return 'Offline';
      }
    }

    final color = getThemeColor();
    final bg = getBgColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in colored circle
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(height: 8.h),

            // Title
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            // Status Tag text
            Text(
              getStatusText(),
              style: TextStyle(
                color: color,
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
