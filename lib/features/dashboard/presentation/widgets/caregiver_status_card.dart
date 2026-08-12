import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/clay_container.dart';

/// Caregiver Status Card displaying active caregiver monitoring status
/// or parent schedule timer in a soft claymorphic container.
class CaregiverStatusCard extends StatefulWidget {
  final bool isCaregiver;
  final DateTime? expiresAt;
  final String? activeCaregiverName;
  final VoidCallback? onLogoutExpired;

  const CaregiverStatusCard({
    super.key,
    this.isCaregiver = false,
    this.expiresAt,
    this.activeCaregiverName,
    this.onLogoutExpired,
  });

  @override
  State<CaregiverStatusCard> createState() => _CaregiverStatusCardState();
}

class _CaregiverStatusCardState extends State<CaregiverStatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isCaregiver) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemainingTime() {
    if (widget.expiresAt == null) return 'Active Session';
    final now = DateTime.now();
    final diff = widget.expiresAt!.difference(now);
    if (diff.isNegative) {
      if (widget.onLogoutExpired != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onLogoutExpired!();
        });
      }
      return '00h 00m 00s (Expired)';
    }
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCaregiver) {
      final remainingStr = _formatRemainingTime();
      return ClayContainer(
        borderRadius: 24,
        gradient: AppColors.primaryGradient,
        shadows: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PARENT SCHEDULED ACCESS REMAINING',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remainingStr,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/join-shared-baby'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.royalBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Scan QR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.activeCaregiverName == null || widget.activeCaregiverName!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final caregiverName = widget.activeCaregiverName!;

    return ClayContainer(
      borderRadius: 22,
      onTap: () => context.push('/caregiver-access'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadows: AppColors.clayShadow,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.softMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: Color(0xFF047857),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$caregiverName is monitoring',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Authorized live access',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Manage',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
