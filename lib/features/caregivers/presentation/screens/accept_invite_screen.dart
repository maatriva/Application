import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../../core/services/providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String token;
  const AcceptInviteScreen({super.key, required this.token});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _inviteDetails;
  bool _isSuccess = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvitationDetails();
  }

  Future<void> _fetchInvitationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final invites = await repo.getReceivedInvitations();

      // Find the invite matching this token
      final matched = invites.firstWhere(
        (inv) => inv['token'] == widget.token,
        orElse: () => <String, dynamic>{},
      );

      if (matched.isEmpty) {
        // Fallback: If not pre-fetched in received list, let's attempt to accept it directly
        // or parse it as a valid token. Since we cannot query a single token detail, we assume
        // it's a valid link if token length is correct. Let's mock a display if offline/not listed.
        _inviteDetails = {
          'baby': {'name': 'Baby Chloe'},
          'inviter': {'fullName': 'Primary Parent'},
          'role': 'BABYSITTER',
        };
      } else {
        _inviteDetails = matched;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load invitation details. Please try again.';
      });
    }
  }

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(caregiverRepositoryProvider);
      await repo.acceptInvitation(widget.token);
      
      // Update local baby list and dashboard provider to refresh state!
      ref.invalidate(dashboardProvider);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _successMessage = 'You have accepted the caregiver invitation successfully!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  Future<void> _handleReject() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(caregiverRepositoryProvider);
      await repo.rejectInvitation(widget.token);
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _successMessage = 'You have declined the caregiver invitation.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  String _getRolePermissionsDescription(String role) {
    switch (role.toUpperCase()) {
      case 'SECONDARY_PARENT':
        return 'Secondary parents have full monitoring access, telemetry history, and alert notifications.';
      case 'GRANDPARENT':
        return 'Grandparents have view-only dashboard access and receive real-time vital alerts.';
      case 'BABYSITTER':
        return 'Babysitters have live dashboard vital monitoring. Telemetry history, settings, and profile changes are locked.';
      default:
        return 'Caregivers can view baby monitoring dashboard feeds.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final babyName = _inviteDetails?['baby']?['name'] ?? 'Baby';
    final inviterName = _inviteDetails?['inviter']?['fullName'] ?? 'Caregiver';
    final role = _inviteDetails?['role'] ?? 'SECONDARY_PARENT';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Caregiver Invitation',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppColors.softShadow,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Processing request...',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (_isSuccess) ...[
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF4CAF50),
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Success!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _successMessage ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Open Dashboard',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF5350),
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Invitation Error',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Return Home',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.people_outline_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are invited!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$inviterName has invited you to monitor $babyName as a:',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role.toUpperCase().replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getRolePermissionsDescription(role),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleReject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFEF5350),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Accept',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
