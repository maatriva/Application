import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';

/// Reusable Access Restricted / Access Removed screen widget for Caretakers.
/// Displayed when a caretaker user attempts to access or is currently on
/// a protected section (AI, Health, Shop) without parent-granted permission.
class CaretakerAccessRestrictedWidget extends StatelessWidget {
  final String title;
  final String message;
  final int tabIndex;
  final VoidCallback? onGoBack;

  const CaretakerAccessRestrictedWidget({
    super.key,
    this.title = 'Access Restricted',
    required this.message,
    required this.tabIndex,
    this.onGoBack,
  });

  /// Factory constructor for unauthorized/no permission access attempt
  factory CaretakerAccessRestrictedWidget.restricted({
    required String sectionName,
    required int tabIndex,
    VoidCallback? onGoBack,
  }) {
    return CaretakerAccessRestrictedWidget(
      title: 'Access Restricted',
      message:
          'You are not authorised to access this section.\n\nPlease ask the parent to enable access.',
      tabIndex: tabIndex,
      onGoBack: onGoBack,
    );
  }

  /// Factory constructor for real-time permission revocation
  factory CaretakerAccessRestrictedWidget.removed({
    required String sectionName,
    required int tabIndex,
    VoidCallback? onGoBack,
  }) {
    return CaretakerAccessRestrictedWidget(
      title: 'Access Restricted',
      message:
          'You are not authorised to access this section.\n\nPlease ask the parent to enable access.',
      tabIndex: tabIndex,
      onGoBack: onGoBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRevoked = title.toLowerCase().contains('removed');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Maatriva Access',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.navyDeep,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDeep),
          onPressed: () {
            if (onGoBack != null) {
              onGoBack!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isRevoked
                      ? const Color(0xFFFFCDD2)
                      : AppColors.royalBlue.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRevoked
                        ? const Color(0xFFE53935).withValues(alpha: 0.08)
                        : AppColors.royalBlue.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isRevoked
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRevoked
                          ? Icons.block_rounded
                          : Icons.lock_person_outlined,
                      size: 38,
                      color: isRevoked
                          ? const Color(0xFFE53935)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Go Back Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (onGoBack != null) {
                          onGoBack!();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: Colors.white),
                      label: Text(
                        'Go Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: tabIndex),
    );
  }
}
