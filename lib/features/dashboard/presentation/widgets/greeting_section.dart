import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class GreetingSection extends ConsumerStatefulWidget {
  final String motherName;
  final String babyStatus;
  final bool isCaregiver;
  final DateTime? expiresAt;

  const GreetingSection({
    super.key,
    required this.motherName,
    required this.babyStatus,
    this.isCaregiver = false,
    this.expiresAt,
  });

  @override
  ConsumerState<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends ConsumerState<GreetingSection> {
  Timer? _timer;
  bool _hasTriggeredLogout = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCaregiver) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(GreetingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCaregiver && _timer == null) {
      _startTimer();
    } else if (!widget.isCaregiver && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemainingTime() {
    if (widget.expiresAt == null) {
      return "Active Session";
    }
    final now = DateTime.now();
    final difference = widget.expiresAt!.difference(now);
    if (difference.isNegative) {
      if (widget.isCaregiver && !_hasTriggeredLogout) {
        _hasTriggeredLogout = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Caregiver access duration set by parent has expired. Automatically logging out...'),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              ),
            );
            ref.read(authNotifierProvider.notifier).logout();
          }
        });
      }
      return "00h 00m 00s (Expired)";
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCaregiver) {
      final remainingStr = _formatRemainingTime();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Caretaker Dashboard',
                  style: AppTypography.displayHeader,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Parent Schedule',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
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
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARENT DECIDED ACCESS REMAINING',
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
              ],
            ),
          ),
        ],
      );
    }

    String subtext = "Your little one is having a peaceful morning.";
    if (widget.babyStatus.toLowerCase() == 'crying' ||
        widget.babyStatus.toLowerCase() == 'awake') {
      subtext = "Your little one is awake and needs your attention.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good Morning, ${widget.motherName}', style: AppTypography.displayHeader),
        const SizedBox(height: 6),
        Text(
          subtext,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
