import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/routes/app_routes.dart';

/// Clean, modern widget displayed when a caretaker/caregiver is unauthorized or unauthenticated.
/// Features a prominent explanation message and a primary Login button that redirects to the Login screen.
class UnauthorizedCaretakerCard extends StatelessWidget {
  final String? customTitle;
  final String? customMessage;
  final String? customButtonText;
  final VoidCallback? onLoginTap;
  final bool isCompact;

  const UnauthorizedCaretakerCard({
    super.key,
    this.customTitle,
    this.customMessage,
    this.customButtonText,
    this.onLoginTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = customTitle ?? 'Caretaker Authorization Required';
    final messageText = customMessage ??
        'You are currently not authorized or logged in as a caretaker. Please log in with a valid caretaker account to access baby monitoring, live telemetry, and caregiver features.';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 16.0,
        vertical: isCompact ? 8.0 : 16.0,
      ),
      padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Security / Lock Icon Badge
          Container(
            width: isCompact ? 56.0 : 68.0,
            height: isCompact ? 56.0 : 68.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.lock_person_outlined,
                size: isCompact ? 28.0 : 36.0,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12.0 : 18.0),

          // Title
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isCompact ? 17.0 : 20.0,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 8.0),

          // Message Body
          Text(
            messageText,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isCompact ? 12.5 : 14.0,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isCompact ? 16.0 : 24.0),

          // Redirect to Login Screen Button
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton.icon(
              onPressed: () {
                if (onLoginTap != null) {
                  onLoginTap!();
                } else {
                  context.go(AppRoutes.login);
                }
              },
              icon: const Icon(Icons.login_rounded, size: 20, color: Colors.white),
              label: Text(
                customButtonText ?? 'Login First',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
          ),

          if (!isCompact) ...[
            const SizedBox(height: 12.0),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: Text(
                'Don\'t have a caretaker account? Register',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
