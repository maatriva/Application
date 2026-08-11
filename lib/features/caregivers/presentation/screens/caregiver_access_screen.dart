import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../../provider/caregiver_access_provider.dart';
import '../widgets/caregiver_header.dart';
import '../widgets/share_access_card.dart';
import '../widgets/duration_selector.dart';
import '../widgets/permission_card.dart';
import '../widgets/active_session_card.dart';
import '../widgets/access_history_card.dart';
import '../widgets/custom_clock_time_picker.dart';
import 'package:maatriva/shared/models/caregiver.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class CaregiverAccessScreen extends ConsumerStatefulWidget {
  const CaregiverAccessScreen({super.key});

  @override
  ConsumerState<CaregiverAccessScreen> createState() =>
      _CaregiverAccessScreenState();
}

class _CaregiverAccessScreenState extends ConsumerState<CaregiverAccessScreen> {

  static const Map<String, IconData> permIcons = {
    'live_monitoring': Icons.videocam_outlined,
    'health_data': Icons.favorite_border_rounded,
    'ai_assistant': Icons.smart_toy_outlined,
    'notifications': Icons.notifications_outlined,
    'emergency_alerts': Icons.warning_amber_rounded,
    'camera_snapshot': Icons.photo_camera_outlined,
    'custom_music': Icons.library_music_outlined,
    'music': Icons.music_note_outlined,
    'cradle_controls': Icons.tune_outlined,
  };

  static const Map<String, String> permTitles = {
    'live_monitoring': 'Live Monitoring',
    'health_data': 'Telemetry & Health Data',
    'ai_assistant': 'AI Pediatrician',
    'notifications': 'Notifications',
    'emergency_alerts': 'Alerts',
    'camera_snapshot': 'Camera',
    'custom_music': 'Custom Lullabies',
    'music': 'Music',
    'cradle_controls': 'Cradle Controls',
  };

  static const Map<String, String> permDescs = {
    'live_monitoring': 'Real-time video & audio feed',
    'health_data': 'Sleep patterns & vitals history',
    'ai_assistant': 'Allow caregiver to ask the AI assistant',
    'notifications': 'Receive important baby alerts',
    'emergency_alerts': 'Critical emergency notifications',
    'camera_snapshot': 'Allow viewing captured images & snapshots',
    'custom_music': 'Access to parent custom lullabies',
    'music': 'Access default music library',
    'cradle_controls': 'Control cradle rocking & soothing',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverAccessProvider);
    final notifier = ref.read(caregiverAccessProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isCaregiver = authState.session?.role == UserRole.caregiver;

    final liveSessionsCount = state.activeSessions.where((s) {
      final remaining = s.expiresAt.difference(DateTime.now());
      return !remaining.isNegative;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          isCaregiver ? 'Parent Granted Access Timings' : 'Caregiver QR Access',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              )
            : null,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered elegant headers
            const CaregiverHeader(),

            // 1. Temporary Access duration selection bubbles (Decided time by parent)
            DurationSelector(
              selectedLabel: state.selectedDurationLabel,
              isCaregiver: isCaregiver,
              onSelected: (label) {
                notifier.selectDuration(label);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Set access duration limit to: $label. Generating QR code...'),
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // 2. Share Access QR code section card (Only for parents)
            if (!isCaregiver)
              ShareAccessCard(
                qrToken: state.qrToken,
                isLoading: state.isGeneratingQR,
                qrError: state.qrError,
                onRetry: () => notifier.retryGenerateQR(),
              ),
            const SizedBox(height: 16),

            // Permissions section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            ...state.permissions.entries.map((entry) {
              final key = entry.key;
              final val = entry.value;
              return PermissionCard(
                title: permTitles[key] ?? key,
                description: permDescs[key] ?? '',
                icon: permIcons[key] ?? Icons.settings_rounded,
                value: val,
                onChanged: (_) {
                  notifier.togglePermission(key);
                },
              );
            }),
            const SizedBox(height: 24),

            // Active Sessions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Active Sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$liveSessionsCount Live',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (state.activeSessions.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 40,
                      color: AppColors.textSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No Active Guest Tokens',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Invite caregivers by tapping "Generate New QR" below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...state.activeSessions.map((session) {
                return ActiveSessionCard(
                  session: session,
                  onExtend: () => _showExtendAccessDialog(context, notifier, session),
                  onRevoke: () {
                    notifier.revokeSession(session.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Revoked all access tokens for ${session.name}.',
                        ),
                        backgroundColor: const Color(0xFFE53935),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: 24),

            // Access History Log Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Access History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            if (state.accessHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'No historical logs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.accessHistory.length,
                itemBuilder: (context, index) {
                  final item = state.accessHistory[index];
                  return AccessHistoryCard(item: item);
                },
              ),
          ],
        ),
      ),

      // Bottom Navigation integrated matching the exact Maatriva active bubble style (index 3: Profile)
      bottomNavigationBar: const BottomNavigation(currentIndex: -1),
    );
  }

  void _showExtendAccessDialog(
    BuildContext context,
    CaregiverAccessNotifier notifier,
    ActiveSession session,
  ) {
    final customMinutesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Extend Access for ${session.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose extension duration:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('+15 Mins'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await notifier.extendTemporaryAccess(
                      permissionId: session.id,
                      extensionMinutes: 15,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Extended access for ${session.name} by 15 minutes.')),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('+30 Mins'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await notifier.extendTemporaryAccess(
                      permissionId: session.id,
                      extensionMinutes: 30,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Extended access for ${session.name} by 30 minutes.')),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('+1 Hour'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await notifier.extendTemporaryAccess(
                      permissionId: session.id,
                      extensionMinutes: 60,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Extended access for ${session.name} by 1 hour.')),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Clock Picker'),
                  onPressed: () async {
                    Navigator.pop(context);
                    final customTime = await CustomClockTimePicker.show(
                      context,
                      initialLabel: '1 Hour',
                      onTimeSelected: (_) {},
                    );
                    if (customTime != null && customTime.isNotEmpty) {
                      final mins = notifier.parseCustomDuration(customTime).inMinutes;
                      if (mins > 0) {
                        await notifier.extendTemporaryAccess(
                          permissionId: session.id,
                          extensionMinutes: mins,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Extended access for ${session.name} by $customTime.')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customMinutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Custom Duration (Minutes)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(customMinutesController.text.trim());
              if (minutes != null && minutes > 0) {
                Navigator.pop(context);
                await notifier.extendTemporaryAccess(
                  permissionId: session.id,
                  extensionMinutes: minutes,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Extended access for ${session.name} by $minutes minutes.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Extend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
