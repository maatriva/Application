import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/models/vitals_telemetry.dart';
import 'package:maatriva/shared/widgets/clay_container.dart';

/// "Baby's Wellness" section displaying 4 claymorphic metric cards
/// (Heart Rate, Respiration, Room Temperature, Humidity) with live telemetry values.
class WellnessSection extends StatelessWidget {
  final Map<String, VitalsTelemetry>? telemetry;
  final bool isRestricted;

  const WellnessSection({
    super.key,
    this.telemetry,
    this.isRestricted = false,
  });

  @override
  Widget build(BuildContext context) {
    final heartRate = telemetry?['heart_rate']?.value.toInt().toString() ?? '--';
    final breathingRate = telemetry?['breathing_rate']?.value.toInt().toString() ?? '--';
    final roomTemp = telemetry?['room_temperature']?.value.toStringAsFixed(1) ?? telemetry?['body_temperature']?.value.toStringAsFixed(1) ?? '--';
    final humidity = telemetry?['humidity']?.value.toInt().toString() ?? '--';

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final isMediumPhone = screenWidth < 400;

    final childAspectRatio = isSmallPhone
        ? 1.12
        : (isMediumPhone ? 1.20 : 1.30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Baby's Wellness",
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDeep,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!isRestricted) {
                  context.push('/telemetry-history?type=heart_rate');
                }
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.royalBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Claymorphic Metric Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildWellnessCard(
              context: context,
              title: 'Heart Rate',
              value: heartRate,
              unit: 'bpm',
              icon: Icons.favorite_rounded,
              iconBgColor: AppColors.heartBg,
              iconColor: AppColors.heartIcon,
              trend: 'Optimal (70-110)',
              sensorType: 'heart_rate',
            ),
            _buildWellnessCard(
              context: context,
              title: 'Respiration',
              value: breathingRate,
              unit: '/min',
              icon: Icons.air_rounded,
              iconBgColor: const Color(0xFFEBF3FF),
              iconColor: const Color(0xFF3B82F6),
              trend: 'Normal rhythm',
              sensorType: 'breathing_rate',
            ),
            _buildWellnessCard(
              context: context,
              title: 'Room Temp',
              value: roomTemp == '--' ? '--' : '$roomTemp°C',
              unit: '',
              icon: Icons.thermostat_rounded,
              iconBgColor: AppColors.tempBg,
              iconColor: AppColors.tempIcon,
              trend: 'Comfortable',
              sensorType: 'room_temperature',
            ),
            _buildWellnessCard(
              context: context,
              title: 'Humidity',
              value: humidity == '--' ? '--' : '$humidity%',
              unit: '',
              icon: Icons.water_drop_rounded,
              iconBgColor: const Color(0xFFE0F7FA),
              iconColor: const Color(0xFF00ACC1),
              trend: 'Ideal range',
              sensorType: 'humidity',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWellnessCard({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String trend,
    required String sensorType,
  }) {
    return ClayContainer(
      onTap: isRestricted
          ? null
          : () => context.push('/telemetry-history?type=$sensorType'),
      borderRadius: 22,
      padding: const EdgeInsets.all(12),
      shadows: AppColors.clayShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_flat_rounded, size: 11, color: Color(0xFF059669)),
                    const SizedBox(width: 2),
                    Text(
                      'Live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                trend,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
