import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/routes/app_routes.dart';
import 'package:maatriva/shared/models/caregiver.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../provider/caregiver_access_provider.dart';
import '../widgets/countdown_flip_clock.dart';
import '../widgets/qr_code_card.dart';
import '../widgets/access_history_card.dart';

import '../widgets/unauthorized_caretaker_card.dart';

/// Main Parent & Caregiver Access Control Screen supporting 5 distinct states:
/// STATE 1: No Active Caregiver (Welcome graphic + "+ Generate Caregiver QR" button)
/// STATE 2: QR Generated / Waiting for Caregiver scan
/// STATE 3: Active Caregiver (🟢 LIVE + Real-time Countdown Flip Clock + Manage/Revoke)
/// STATE 4 & 5: Access Expired / Revoked (Access History + "Generate New Access" button)
class CaregiverAccessScreen extends ConsumerStatefulWidget {
  const CaregiverAccessScreen({super.key});

  @override
  ConsumerState<CaregiverAccessScreen> createState() =>
      _CaregiverAccessScreenState();
}

class _CaregiverAccessScreenState extends ConsumerState<CaregiverAccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(caregiverAccessProvider.notifier).loadSessions(loadHistory: true);
    });
  }

  static const Map<String, String> permTitles = {
    'custom_music': 'Custom Parent Folder',
    'health_data': 'Baby\'s Wellness & Sensor Readings',
    'ai_assistant': 'AI Chatbot',
    'emergency_alerts': 'Real-Time Alerts & Notifications',
    'camera_snapshot': 'Live Video',
    'cradle_controls': 'Cradle Controls',
  };

  void _showSingleCaregiverNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active Caregiver Exists',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'An active caregiver already has access to your baby.\n\nOnly ONE active caregiver is permitted at a time. You must revoke the existing caregiver before creating a new access invitation.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Got It',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRevoke(BuildContext context, ActiveSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Revoke Caregiver Access?',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFFEF4444),
            ),
          ),
          content: Text(
            '${session.name} will immediately lose access to your baby\'s information and live telemetry.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final notifier = ref.read(caregiverAccessProvider.notifier);
                await notifier.revokeSession(session.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Access for ${session.name} has been revoked.'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Revoke Access',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverAccessProvider);
    final notifier = ref.read(caregiverAccessProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final isUnauthenticated = authState.status != AuthStatus.authenticated;

    final activeSession = state.activeSessions.isNotEmpty
        ? state.activeSessions.firstWhere(
            (s) => s.status == SessionStatus.active || s.status == SessionStatus.expiring,
            orElse: () => state.activeSessions.first,
          )
        : null;

    final hasActiveCaregiver = activeSession != null &&
        !activeSession.expiresAt
            .difference(DateTime.now().add(state.serverClockOffset))
            .isNegative;

    final hasPendingQR = !hasActiveCaregiver && state.qrToken.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background, // Pale aqua canvas #EBF7F8
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          isCaregiver ? 'Caregiver Access Status' : 'Caregiver Access',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UNAUTHENTICATED CARETAKER GUARD
            if (isUnauthenticated) ...[
              const UnauthorizedCaretakerCard(),
            ]
            // EXPIRED / REVOKED CAREGIVER ROLE GUARD
            else if (isCaregiver && !hasActiveCaregiver) ...[
              const UnauthorizedCaretakerCard(
                customTitle: 'Caregiver Access Expired or Revoked',
                customMessage:
                    'Your caregiver monitoring session is inactive, expired, or revoked by the parent. Please log in with a valid caretaker account to accept a new QR invitation.',
              ),
            ]
            // STATE 3: ACTIVE CAREGIVER EXISTS
            else if (hasActiveCaregiver) ...[
              _buildState3ActiveCaregiver(activeSession!, state.serverClockOffset),
            ]
            // STATE 2: PENDING QR GENERATED
            else if (hasPendingQR) ...[
              _buildState2QRWaiting(state, notifier),
            ]
            // STATE 1: NO ACTIVE CAREGIVER
            else ...[
              _buildState1NoCaregiver(),
            ],

            const SizedBox(height: 24),

            // ACCESS HISTORY SECTION (States 4 & 5)
            if (state.accessHistory.isNotEmpty) ...[
              Text(
                'Access History',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...state.accessHistory.map((h) => AccessHistoryCard(item: h)),
            ],
          ],
        ),
      ),
    );
  }

  // STATE 1: NO ACTIVE CAREGIVER
  Widget _buildState1NoCaregiver() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.predictiveCardBg, // Pale aqua #EAF8F7
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: AppColors.predictiveClayShadow,
          ),
          child: Column(
            children: [
              // Friendly Maatriva Illustration Container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.child_care_rounded,
                    size: 52,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Caregiver Access',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share temporary, real-time access with someone you trust.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Large Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(AppRoutes.createCaregiverAccess);
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
                      const Icon(Icons.add_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Caregiver QR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Give a trusted caregiver temporary access to your baby\'s care.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 2: QR GENERATED / WAITING
  Widget _buildState2QRWaiting(
    CaregiverAccessState state,
    CaregiverAccessNotifier notifier,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
                    const Icon(Icons.hourglass_empty_rounded,
                        size: 16, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    Text(
                      'Waiting for caregiver...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF57F17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Caregiver Access Ready',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ask the caregiver to scan this code with the Maatriva app.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // QR Code Card
              QRCodeCard(
                qrToken: state.qrToken,
                isLoading: state.isGeneratingQR,
                qrError: state.qrError,
              ),

              const SizedBox(height: 16),
              Text(
                'Configured Duration: ${state.selectedDurationLabel}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(height: 20),

              // Cancel Invitation Button
              TextButton(
                onPressed: () {
                  notifier.cancelPendingQR();
                },
                child: Text(
                  'Cancel Invitation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 3: ACTIVE CAREGIVER
  Widget _buildState3ActiveCaregiver(ActiveSession session, Duration serverClockOffset) {
    final expiresFormatted =
        'Today • ${_formatTime(session.expiresAt)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE CAREGIVER SESSION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Caregiver Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(session.imageUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDeep,
                          ),
                        ),
                        Text(
                          session.relationship,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🟢 Access Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Countdown Flip Clock Widget
              CountdownFlipClock(
                targetExpiry: session.expiresAt,
                serverClockOffset: serverClockOffset,
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: $expiresFormatted',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '${AppRoutes.caregiverManage}?id=${session.id}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Manage Access',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmRevoke(context, session),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5),
                        foregroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Revoke Access',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Disabled "+ Generate Caregiver QR" notice if tapped
        GestureDetector(
          onTap: () => _showSingleCaregiverNotice(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '+ Generate Caregiver QR (1 Active Limit)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}
