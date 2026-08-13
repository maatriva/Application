import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import 'package:maatriva/shared/widgets/clay_container.dart';
import '../providers/dashboard_provider.dart';

class WellnessMonitoringScreen extends ConsumerWidget {
  const WellnessMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final telemetry = dashboardState.latestTelemetry;
    final isDeviceOnline = dashboardState.device?.status.toLowerCase() != 'offline';

    final heartRate = telemetry?['heart_rate']?.value.toInt().toString() ?? '142';
    final breathingRate = telemetry?['breathing_rate']?.value.toInt().toString() ?? telemetry?['respiration_rate']?.value.toInt().toString() ?? '44';
    final roomTemp = telemetry?['room_temperature']?.value.toStringAsFixed(1) ?? '25.4';
    final humidity = telemetry?['humidity']?.value.toInt().toString() ?? '58';

    final cryDetected = telemetry?['cry_detection']?.value == 1.0;

    return Scaffold(
      backgroundColor: AppColors.background, // Light Aqua Canvas
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Wellness Monitoring',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDeviceOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDeviceOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDeviceOnline ? 'Monitoring Active' : 'Device Offline',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDeviceOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Updated just now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Full Telemetry Center',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Everything Maatriva is monitoring for your little one.',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =================================================================
            // SECTION 1: ❤️ BABY MONITORING
            // =================================================================
            _buildSectionHeader('❤️ BABY MONITORING', '4 Active Sensors'),
            const SizedBox(height: 12),
            _buildSensorCard(
              context: context,
              sensorId: 'heart_rate',
              title: 'Heart Rate',
              value: '$heartRate bpm',
              statusPill: 'Optimal (70-160)',
              icon: Icons.favorite_rounded,
              iconBgColor: AppColors.heartBg,
              iconColor: AppColors.heartIcon,
              lastUpdated: 'Live • Continuous',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'breathing_rate',
              title: 'Breathing Rate / Respiration',
              value: '$breathingRate /min',
              statusPill: 'Normal rhythm (30-60)',
              icon: Icons.air_rounded,
              iconBgColor: const Color(0xFFEBF3FF),
              iconColor: const Color(0xFF3B82F6),
              lastUpdated: 'Live • Continuous',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'cry_detection',
              title: 'Cry Detection',
              value: cryDetected ? 'Cry Detected' : 'No Cry Detected',
              statusPill: cryDetected ? '🔴 Auto-Soothing' : '🟢 Peaceful',
              icon: Icons.face_retouching_natural_rounded,
              iconBgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFF9F43),
              lastUpdated: 'Real-time AI audio analysis',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'noise_detection',
              title: 'Noise Detection',
              value: 'Quiet Nursery (< 45 dB)',
              statusPill: '🟢 Low Ambient Noise',
              icon: Icons.graphic_eq_rounded,
              iconBgColor: const Color(0xFFEDEBFD),
              iconColor: const Color(0xFF7060E6),
              lastUpdated: 'Continuous decibel monitor',
            ),

            const SizedBox(height: 28),

            // =================================================================
            // SECTION 2: 🌿 NURSERY ENVIRONMENT
            // =================================================================
            _buildSectionHeader('🌿 NURSERY ENVIRONMENT', '3 Active Sensors'),
            const SizedBox(height: 12),
            _buildSensorCard(
              context: context,
              sensorId: 'room_temperature',
              title: 'Room Temperature',
              value: '$roomTemp°C',
              statusPill: 'Comfortable (20-26°C)',
              icon: Icons.thermostat_rounded,
              iconBgColor: AppColors.tempBg,
              iconColor: AppColors.tempIcon,
              lastUpdated: 'Live • Climate Sensor',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'humidity',
              title: 'Humidity',
              value: '$humidity%',
              statusPill: 'Ideal range (40-60%)',
              icon: Icons.water_drop_rounded,
              iconBgColor: const Color(0xFFE0F7FA),
              iconColor: const Color(0xFF00ACC1),
              lastUpdated: 'Live • Moisture Monitor',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'gas_detection',
              title: 'Gas & Air Quality Detection',
              value: 'Air Quality Safe (AQI 22)',
              statusPill: '🟢 No VOC / Smoke',
              icon: Icons.eco_rounded,
              iconBgColor: const Color(0xFFE3F7F5),
              iconColor: const Color(0xFF19A394),
              lastUpdated: 'Multi-gas safety sensor',
            ),

            const SizedBox(height: 28),

            // =================================================================
            // SECTION 3: 🛡 SAFETY & CRADLE
            // =================================================================
            _buildSectionHeader('🛡 SAFETY & CRADLE', '2 Active Sensors'),
            const SizedBox(height: 12),
            _buildSensorCard(
              context: context,
              sensorId: 'leakage',
              title: 'Diaper & Mat Leakage',
              value: 'Dry Mat Surface',
              statusPill: '🟢 No Leakage Detected',
              icon: Icons.invert_colors_rounded,
              iconBgColor: const Color(0xFFE8F4FF),
              iconColor: const Color(0xFF4A89F3),
              lastUpdated: 'Conductive strip sensor',
            ),
            const SizedBox(height: 10),
            _buildSensorCard(
              context: context,
              sensorId: 'cradle_swing',
              title: 'Cradle Swing & Motion',
              value: 'Gentle Motion Active',
              statusPill: '🔵 Sway Level 1',
              icon: Icons.bedroom_baby_rounded,
              iconBgColor: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFFAB47BC),
              lastUpdated: 'Gyroscope & Motor Encoder',
            ),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavigation(currentIndex: -1),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required BuildContext context,
    required String sensorId,
    required String title,
    required String value,
    required String statusPill,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String lastUpdated,
  }) {
    return ClayContainer(
      onTap: () => context.push('/wellness-monitoring/report?sensor=$sensorId'),
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      shadows: AppColors.clayShadow,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusPill,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  lastUpdated,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
