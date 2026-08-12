import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/models/baby_profile.dart';
import 'package:maatriva/shared/models/vitals_telemetry.dart';
import 'package:maatriva/shared/widgets/clay_container.dart';

/// Hero Card positioned at the top of the Home Dashboard.
/// Communicates "Is my baby okay?" within 2-3 seconds using emotional reassurance,
/// real dynamic baby state, and an inline quick vitals strip.
class BabyStatusHeroCard extends StatelessWidget {
  final BabyProfile baby;
  final Map<String, VitalsTelemetry>? telemetry;
  final VoidCallback? onTap;

  const BabyStatusHeroCard({
    super.key,
    required this.baby,
    this.telemetry,
    this.onTap,
  });

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final months = (difference.inDays / 30.4).floor();
    if (months < 1) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks old';
    }
    if (months >= 12) {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year${years > 1 ? 's' : ''} old';
      }
      return '$years yr $remainingMonths mo old';
    }
    return '$months months old';
  }

  Map<String, String> _getBabyVisualState() {
    if (telemetry == null || telemetry!.isEmpty) {
      return {
        'stateText': 'Sleeping peacefully 😴',
        'statusMessage': 'Everything looks good',
        'isAlert': 'false',
      };
    }

    final cryVal = telemetry!['cry_detection']?.value ?? 0.0;
    if (cryVal > 0) {
      return {
        'stateText': 'May need your attention 🥺',
        'statusMessage': 'Baby cry detected',
        'isAlert': 'true',
      };
    }

    final sleepVal = telemetry!['sleep_stage']?.value ?? 0.0;
    if (sleepVal > 0) {
      return {
        'stateText': 'Sleeping peacefully 😴',
        'statusMessage': 'Everything looks good',
        'isAlert': 'false',
      };
    }

    final movementVal = telemetry!['movement_detection']?.value ?? 0.0;
    if (movementVal > 0) {
      return {
        'stateText': 'Moving around 🐣',
        'statusMessage': 'Active & safe',
        'isAlert': 'false',
      };
    }

    return {
      'stateText': 'Awake & Active ☀️',
      'statusMessage': 'Everything looks good',
      'isAlert': 'false',
    };
  }

  @override
  Widget build(BuildContext context) {
    final visualState = _getBabyVisualState();
    final isAlert = visualState['isAlert'] == 'true';

    final heartRate = telemetry?['heart_rate']?.value.toInt().toString() ?? '--';
    final breathingRate = telemetry?['breathing_rate']?.value.toInt().toString() ?? '--';
    final roomTemp = telemetry?['room_temperature']?.value.toStringAsFixed(1) ?? telemetry?['body_temperature']?.value.toStringAsFixed(1) ?? '--';
    final humidity = telemetry?['humidity']?.value.toInt().toString() ?? '--';

    return ClayContainer(
      onTap: onTap,
      borderRadius: 28,
      gradient: AppColors.heroCardGradient,
      shadows: AppColors.clayHeroShadow,
      border: Border.all(
        color: isAlert
            ? Colors.orangeAccent.withValues(alpha: 0.5)
            : AppColors.royalBlue.withValues(alpha: 0.12),
        width: 1.5,
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background soft nursery accents (cloud & stars)
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.cloud_queue_rounded,
              size: 80,
              color: AppColors.royalBlue.withValues(alpha: 0.05),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Baby Info & Dynamic Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with clay highlight ring
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.15),
                          AppColors.lavenderAccent.withValues(alpha: 0.25),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          baby.gender.toLowerCase() == 'female'
                              ? Icons.child_care_rounded
                              : Icons.face_rounded,
                          color: AppColors.royalBlue,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name, Age & Purple Heart
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                baby.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('💜', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _calculateAge(baby.birthDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Overall Safety Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAlert
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE6F8F3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAlert
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF80DFCA),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAlert ? Colors.orange : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAlert ? 'Needs Care' : 'All Clear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAlert ? Colors.orange.shade900 : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Status Reassurance Card Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isAlert
                      ? const Color(0xFFFFF8F0)
                      : const Color(0xFFF3FAF9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isAlert
                        ? Colors.orange.withValues(alpha: 0.2)
                        : const Color(0xFFB9E4E5).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        visualState['stateText']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAlert
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            size: 14,
                            color: isAlert ? Colors.orange : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              visualState['statusMessage']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAlert ? Colors.orange.shade800 : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Quick Vitals Strip with horizontal scroll / responsive layout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDeep.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildVitalChip(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.heartIcon,
                        bgColor: AppColors.heartBg,
                        value: heartRate,
                        unit: 'BPM',
                      ),
                      _buildDivider(),
                      _buildVitalChip(
                        icon: Icons.air_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        value: breathingRate,
                        unit: '/min',
                      ),
                      _buildDivider(),
                      _buildVitalChip(
                        icon: Icons.thermostat_rounded,
                        iconColor: AppColors.tempIcon,
                        bgColor: AppColors.tempBg,
                        value: roomTemp == '--' ? '--' : '$roomTemp°C',
                        unit: 'Temp',
                      ),
                      _buildDivider(),
                      _buildVitalChip(
                        icon: Icons.water_drop_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        bgColor: const Color(0xFFF0F9FF),
                        value: humidity == '--' ? '--' : '$humidity%',
                        unit: 'Hum',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.divider.withValues(alpha: 0.6),
    );
  }

  Widget _buildVitalChip({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDeep,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
