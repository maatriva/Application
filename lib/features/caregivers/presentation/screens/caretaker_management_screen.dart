import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/models/caregiver.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../../provider/caregiver_access_provider.dart';
import '../widgets/countdown_flip_clock.dart';
import '../widgets/flip_clock_duration_selector.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/unauthorized_caretaker_card.dart';

/// Dedicated Caretaker Management / Access Details Screen.
/// Allows parents to inspect remaining time, extend access, modify permissions, and revoke access.
class CaretakerManagementScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const CaretakerManagementScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<CaretakerManagementScreen> createState() =>
      _CaretakerManagementScreenState();
}

class _CaretakerManagementScreenState
    extends ConsumerState<CaretakerManagementScreen> {
  Timer? _countdownTimer;

  static const Map<String, IconData> permIcons = {
    'custom_music': Icons.folder_shared_outlined,
    'health_data': Icons.monitor_heart_outlined,
    'ai_assistant': Icons.smart_toy_outlined,
    'emergency_alerts': Icons.notifications_active_outlined,
    'camera_snapshot': Icons.videocam_outlined,
    'cradle_controls': Icons.tune_outlined,
  };

  static const Map<String, String> permTitles = {
    'custom_music': 'Custom Parent Folder',
    'health_data': 'Baby\'s Wellness & Sensor Readings',
    'ai_assistant': 'AI Chatbot',
    'emergency_alerts': 'Real-Time Alerts & Notifications',
    'camera_snapshot': 'Live Video',
    'cradle_controls': 'Cradle Controls',
  };

  static const Map<String, String> permDescs = {
    'custom_music': 'Access parent custom audio recordings and lullabies folder',
    'health_data': 'View live baby vitals & telemetry data (live data only, no history)',
    'ai_assistant': 'Allow caregiver to consult AI Pediatrician chatbot',
    'emergency_alerts': 'Receive real-time safety alerts and emergency notifications',
    'camera_snapshot': 'View live nursery video camera feed',
    'cradle_controls': 'Operate smart cradle rocking & soothing controls',
  };

  @override
  void initState() {
    super.initState();
    // Dynamic countdown timer updating remaining time every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatExpiryDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) {
      return '00h : 00m : 00s';
    }
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final mins = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '${hours}h : ${mins}m : ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverAccessProvider);
    final notifier = ref.read(caregiverAccessProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isUnauthenticated = authState.status != AuthStatus.authenticated;

    final session = state.activeSessions.firstWhere(
      (s) => s.id == widget.sessionId,
      orElse: () => state.activeSessions.isNotEmpty
          ? state.activeSessions.first
          : ActiveSession(
              id: widget.sessionId,
              name: 'Caregiver',
              relationship: 'Temporary Caregiver',
              imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120',
              expiresAt: DateTime.now().add(const Duration(minutes: 30)),
              status: SessionStatus.active,
              permissions: state.permissions,
            ),
    );

    final now = DateTime.now();
    final remaining = session.expiresAt.difference(now);
    final isExpired = remaining.isNegative;
    final isExpiringSoon = !isExpired && remaining.inMinutes <= 120;

    // Status colors and badges
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isExpired) {
      statusColor = const Color(0xFFE53935);
      statusLabel = 'Access Expired';
      statusIcon = Icons.cancel_rounded;
    } else if (isExpiringSoon) {
      statusColor = const Color(0xFFF57C00);
      statusLabel = 'Expiring Soon';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusLabel = 'Access Active';
      statusIcon = Icons.check_circle_rounded;
    }

    // Progress value (assuming max 24 hours window for progress bar)
    final double progressValue = isExpired
        ? 0.0
        : (remaining.inSeconds / (24 * 3600)).clamp(0.0, 1.0);

    // Dynamic permissions map
    final sessionPermissions = session.permissions ?? state.permissions;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caretaker Access',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Manage access to your baby\'s Maatriva account',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navyDeep,
          ),
          onPressed: () {
            if (isUnauthenticated) {
              context.go('/login');
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUnauthenticated) ...[
                const UnauthorizedCaretakerCard(),
              ] else ...[
                // -------------------------------------------------------------
                // 3. CARETAKER PROFILE CARD
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF183B70).withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFE4F0F2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Caretaker Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFE8E1FF),
                        backgroundImage: session.imageUrl.isNotEmpty
                            ? NetworkImage(session.imageUrl)
                            : null,
                        child: session.imageUrl.isEmpty
                            ? const Icon(Icons.person, color: AppColors.royalBlue, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Profile Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDeep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session.name.toLowerCase().replaceAll(' ', '')}@example.com',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Relationship: ${session.relationship}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: statusColor),
                                const SizedBox(width: 5),
                                Text(
                                  statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // 5. EXPIRING SOON / EXPIRED WARNING BANNERS
              // -------------------------------------------------------------
              if (isExpired)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: Color(0xFFE53935), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access Expired',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This caretaker no longer has access to your baby\'s information.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFFB71C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (isExpiringSoon)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access expires soon',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your caretaker\'s access will expire in ${remaining.inHours > 0 ? '${remaining.inHours}h ' : ''}${remaining.inMinutes % 60}m.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFFEF6C00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // -------------------------------------------------------------
              // 4. REMAINING ACCESS TIME CARD (COUNTDOWN FLIP CLOCK)
              // -------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(
                    color: const Color(0xFFE4F0F2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REAL-TIME ACCESS COUNTDOWN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Countdown Flip Clock Widget
                    CountdownFlipClock(targetExpiry: session.expiresAt),

                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Access expires:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatExpiryDate(session.expiresAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 6. EXTEND ACCESS BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showExtendBottomSheet(context, notifier, session),
                        icon: const Icon(Icons.more_time_rounded, size: 18),
                        label: Text(
                          'Extend Access',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // -------------------------------------------------------------
              // 7. PERMISSIONS SECTION
              // -------------------------------------------------------------
              Text(
                'Permissions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Control what this caretaker can access',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              ...sessionPermissions.entries.map((entry) {
                final key = entry.key;
                final val = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4F0F2)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183B70).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8E1FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          permIcons[key] ?? Icons.settings_rounded,
                          color: AppColors.royalBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permTitles[key] ?? key,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDeep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              permDescs[key] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Switch Toggle
                      Switch.adaptive(
                        value: val,
                        activeThumbColor: AppColors.royalBlue,
                        onChanged: isExpired
                            ? null
                            : (newVal) async {
                                final updatedMap = Map<String, bool>.from(sessionPermissions);
                                updatedMap[key] = newVal;
                                final success = await notifier.updateTemporaryPermissions(
                                  permissionId: session.id,
                                  permissions: updatedMap,
                                );
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Permissions updated'),
                                        backgroundColor: Color(0xFF00B894),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update permission on server.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              // -------------------------------------------------------------
              // 10. DANGER ZONE / REVOKE ACCESS
              // -------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger Zone',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remove this caretaker\'s access to your baby\'s account.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRevokeConfirmation(context, notifier, session),
                        icon: const Icon(Icons.person_remove_rounded, size: 18),
                        label: Text(
                          'Revoke Caretaker Access',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: -1),
    );
  }

  /// Extend Access Modal Bottom Sheet using Flip Clock
  void _showExtendBottomSheet(
    BuildContext context,
    CaregiverAccessNotifier notifier,
    ActiveSession session,
  ) {
    int selectedExtensionMinutes = 60; // Default 1 hour extension

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.predictiveCanvasBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  FlipClockDurationSelector(
                    title: 'EXTEND ACCESS BY',
                    initialDurationLabel: '1 Hour',
                    showConfirmButton: true,
                    onTotalMinutesChanged: (totalMins) {
                      selectedExtensionMinutes = totalMins;
                    },
                    onDurationChanged: (_) {},
                    onConfirm: () async {
                      Navigator.pop(sheetContext);
                      if (selectedExtensionMinutes <= 0) return;

                      final success = await notifier.extendTemporaryAccess(
                        permissionId: session.id,
                        extensionMinutes: selectedExtensionMinutes,
                      );
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ Extended access for ${session.name} by ${selectedExtensionMinutes ~/ 60 > 0 ? '${selectedExtensionMinutes ~/ 60}h ' : ''}${selectedExtensionMinutes % 60 > 0 ? '${selectedExtensionMinutes % 60}m' : ''}.',
                              ),
                              backgroundColor: const Color(0xFF00B894),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to update access duration.'),
                              backgroundColor: Color(0xFFE53935),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationOption(
    BuildContext sheetContext,
    CaregiverAccessNotifier notifier,
    ActiveSession session,
    String label,
    int minutes,
  ) {
    return ListTile(
      leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.royalBlue),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navyDeep,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () async {
        Navigator.pop(sheetContext);
        final success = await notifier.extendTemporaryAccess(
          permissionId: session.id,
          extensionMinutes: minutes,
        );
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Access extended by $label successfully'),
                backgroundColor: const Color(0xFF00B894),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to extend access.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
    );
  }

  /// Revoke Access Dialog
  void _showRevokeConfirmation(
    BuildContext context,
    CaregiverAccessNotifier notifier,
    ActiveSession session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Revoke Caretaker Access?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.navyDeep,
          ),
        ),
        content: Text(
          '${session.name} will immediately lose access to this baby\'s information and devices.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await notifier.revokeSession(session.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Revoked access for ${session.name}.'),
                    backgroundColor: const Color(0xFFE53935),
                  ),
                );
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Revoke Access',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
