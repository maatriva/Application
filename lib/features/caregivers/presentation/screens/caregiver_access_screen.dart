import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../provider/caregiver_access_provider.dart';
import '../widgets/caregiver_header.dart';
import '../widgets/share_access_card.dart';
import '../widgets/duration_selector.dart';
import '../widgets/permission_card.dart';
import '../widgets/active_session_card.dart';
import '../widgets/access_history_card.dart';

class CaregiverAccessScreen extends ConsumerStatefulWidget {
  const CaregiverAccessScreen({super.key});

  @override
  ConsumerState<CaregiverAccessScreen> createState() =>
      _CaregiverAccessScreenState();
}

class _CaregiverAccessScreenState extends ConsumerState<CaregiverAccessScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedRelationship = 'Nanny';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Opens a custom bottom sheet to generate and register a new caregiver session
  void _showAddCaregiverSheet(
    BuildContext context,
    CaregiverAccessNotifier notifier,
    String durationLabel,
  ) {
    _nameController.clear();
    _selectedRelationship = 'Nanny';

    final relationships = [
      'Grandmother',
      'Grandfather',
      'Nanny',
      'Babysitter',
      'Uncle',
      'Aunt',
      'Friend',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2DCEF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Invite Guest Caregiver',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Generate a custom secure access token valid for $durationLabel.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input: Name
                    const Text(
                      "Caregiver's Name",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Aunt Sarah',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB4AEC1),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F5FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 18),

                    // Relationship Dropdown
                    const Text(
                      'Relationship',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRelationship,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          items: relationships.map((rel) {
                            return DropdownMenuItem(
                              value: rel,
                              child: Text(
                                rel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                _selectedRelationship = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nameController.text.trim().isEmpty
                            ? null
                            : () {
                                final name = _nameController.text.trim();

                                // Random profile photos of warm friendly faces
                                final avatars = [
                                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
                                  'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=150&q=80',
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
                                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
                                ];
                                final mathIndex = name.length % avatars.length;
                                final img = avatars[mathIndex];

                                notifier.addCaregiverSession(
                                  name: name,
                                  relationship: _selectedRelationship,
                                  durationLabel: durationLabel,
                                  imageUrl: img,
                                );

                                notifier.generateNewQR();

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Secure access token generated for $name!',
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2DCEF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Generate Token & QR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverAccessProvider);
    final notifier = ref.read(caregiverAccessProvider.notifier);

    // Filter permissions to readable list
    final Map<String, IconData> permIcons = {
      'live_monitoring': Icons.videocam_outlined,
      'health_data': Icons.favorite_border_rounded,
      'ai_assistant': Icons.smart_toy_outlined,
      'notifications': Icons.notifications_outlined,
      'emergency_alerts': Icons.warning_amber_rounded,
      'camera_snapshot': Icons.photo_camera_outlined,
    };

    final Map<String, String> permTitles = {
      'live_monitoring': 'Live Monitoring',
      'health_data': 'Health Data',
      'ai_assistant': 'AI Assistant',
      'notifications': 'Notifications',
      'emergency_alerts': 'Emergency Alerts',
      'camera_snapshot': 'Camera Snapshot',
    };

    final Map<String, String> permDescs = {
      'live_monitoring': 'Real-time video & audio feed',
      'health_data': 'Sleep patterns & vitals history',
      'ai_assistant': 'Allow caregiver to ask the AI assistant',
      'notifications': 'Receive important baby alerts',
      'emergency_alerts': 'Critical notifications only',
      'camera_snapshot': 'Allow viewing captured images',
    };

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
        title: const Text(
          'Caregiver QR Access',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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

      // Floating Action Button to Generate and register a brand new caregiver session
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddCaregiverSheet(
            context,
            notifier,
            state.selectedDurationLabel,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const Icon(Icons.qr_code_2_rounded, size: 24),
          label: const Text(
            'Generate New QR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 110,
        ), // Room for bottom nav and floating button
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered elegant headers
            const CaregiverHeader(),

            // Share Access QR code section card
            ShareAccessCard(
              qrToken: state.qrToken,
              isLoading: state.isGeneratingQR,
            ),
            const SizedBox(height: 12),

            // Temporary Access duration selection bubbles
            DurationSelector(
              selectedLabel: state.selectedDurationLabel,
              onSelected: (label) {
                notifier.selectDuration(label);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Set access duration limit to: $label'),
                    duration: const Duration(milliseconds: 600),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
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
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3, // Selects the 'Profile' option
        onTap: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 2) {
            context.go('/shop');
          } else if (index == 3) {
            context.go('/profile');
          } else {
            context.go('/');
          }
        },
      ),
    );
  }
}
