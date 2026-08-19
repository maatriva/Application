import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../provider/caregiver_access_provider.dart';
import '../widgets/flip_clock_duration_selector.dart';
import '../widgets/qr_code_card.dart';
import '../widgets/unauthorized_caretaker_card.dart';

/// 4-Step Parent Wizard for creating secure, temporary caregiver access.
/// Step 1: Duration (3-Column Flip Clock + Presets)
/// Step 2: Permissions (Claymorphic cards + Switches)
/// Step 3: Review
/// Step 4: Generate Secure QR Code
class CreateCaregiverAccessScreen extends ConsumerStatefulWidget {
  const CreateCaregiverAccessScreen({super.key});

  @override
  ConsumerState<CreateCaregiverAccessScreen> createState() =>
      _CreateCaregiverAccessScreenState();
}

class _CreateCaregiverAccessScreenState
    extends ConsumerState<CreateCaregiverAccessScreen> {
  int _currentStep = 1;
  String _selectedDurationLabel = '30 Mins';
  int _selectedMinutes = 30;

  Map<String, bool> _permissions = {
    'custom_music': false,      // Custom parent folder
    'health_data': true,        // Live telemetry report (Default: ON)
    'ai_assistant': true,       // AI chatbot (Default: ON)
    'emergency_alerts': true,   // Real time alert and notification (Default: ON)
    'camera_snapshot': false,   // Live video
    'cradle_controls': false,   // Cradle controls
  };

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

  void _generateQR() async {
    final notifier = ref.read(caregiverAccessProvider.notifier);
    await notifier.updatePermissionsConfig(_permissions);
    await notifier.setDurationLabel(_selectedDurationLabel);
    await notifier.retryGenerateQR();

    if (mounted) {
      setState(() {
        _currentStep = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverAccessProvider);

    return Scaffold(
      backgroundColor: AppColors.background, // Pale aqua canvas #EBF7F8
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (ref.read(authNotifierProvider).status != AuthStatus.authenticated) {
              context.go('/login');
            } else if (_currentStep > 1 && _currentStep < 4) {
              setState(() {
                _currentStep--;
              });
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Create Caregiver Access',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ref.watch(authNotifierProvider).status != AuthStatus.authenticated
            ? const UnauthorizedCaretakerCard()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Progress Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 24),

                  if (_currentStep == 1) _buildStep1Duration(),
                  if (_currentStep == 2) _buildStep2Permissions(),
                  if (_currentStep == 3) _buildStep3Review(),
                  if (_currentStep == 4) _buildStep4QR(state),
                ],
              ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(1, 'Duration'),
          _buildStepLine(1),
          _buildStepItem(2, 'Permissions'),
          _buildStepLine(2),
          _buildStepItem(3, 'Review'),
          _buildStepLine(3),
          _buildStepItem(4, 'QR Code'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String label) {
    final isActive = _currentStep == stepNumber;
    final isCompleted = _currentStep > stepNumber;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF00B894)
                : (isActive ? AppColors.primary : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$stepNumber',
                    style: GoogleFonts.plusJakartaSans(
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isDone ? const Color(0xFF00B894) : const Color(0xFFE2E8F0),
      ),
    );
  }

  // STEP 1: Duration Selection
  Widget _buildStep1Duration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1 — SET DURATION',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how long access will remain valid after caregiver scans.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        FlipClockDurationSelector(
          title: 'ACCESS DURATION',
          initialDurationLabel: _selectedDurationLabel,
          onDurationChanged: (label) {
            setState(() {
              _selectedDurationLabel = label;
            });
          },
          onTotalMinutesChanged: (mins) {
            setState(() {
              _selectedMinutes = mins;
            });
          },
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedMinutes > 0
                ? () {
                    setState(() {
                      _currentStep = 2;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Permissions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Permissions Selection
  Widget _buildStep2Permissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 2 — SET PERMISSIONS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select feature-level access for this caregiver session.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        ..._permissions.keys.map((key) {
          final isEnabled = _permissions[key] ?? false;
          final title = permTitles[key] ?? key;
          final desc = permDescs[key] ?? '';
          final icon = permIcons[key] ?? Icons.security;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isEnabled
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.white,
                width: 1.5,
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? AppColors.primary : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _permissions[key] = val;
                    });
                  },
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Review Access',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: Review
  Widget _buildStep3Review() {
    final enabledPerms = _permissions.entries.where((e) => e.value).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 3 — REVIEW CAREGIVER ACCESS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verify configuration before generating the secure QR code.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Duration Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.predictiveCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: AppColors.predictiveClayShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Duration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDurationLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Permissions Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Granted Permissions (${enabledPerms.length})',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 14),
              ..._permissions.entries.map((entry) {
                final isGranted = entry.value;
                final title = permTitles[entry.key] ?? entry.key;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isGranted
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: isGranted
                            ? const Color(0xFF00B894)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight:
                              isGranted ? FontWeight.bold : FontWeight.normal,
                          color: isGranted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _generateQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Generate Secure QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 4: QR Display Screen
  Widget _buildStep4QR(CaregiverAccessState state) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded,
                        size: 16, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    Text(
                      'Waiting for caregiver to scan...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF57F17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Visual
              QRCodeCard(
                qrToken: state.qrToken,
                isLoading: state.isGeneratingQR,
                qrError: state.qrError,
              ),

              const SizedBox(height: 20),
              Text(
                'Selected Access Time: $_selectedDurationLabel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              context.pop();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Done & Return to Main Screen',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
