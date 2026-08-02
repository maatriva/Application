import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:maatriva/features/caregivers/provider/caregiver_access_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../models/song.dart';

class MusicAccessHelper {
  static bool canAccessSong(Song song, WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    final baby = ref.read(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authState.session?.role == UserRole.caregiver ||
        baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    // Primary parents have full access to all music
    if (!isCaregiver) return true;

    // Online app music (in-app lullabies, white noise, etc.) is allowed for Caregivers
    if (!song.isCustomParentSong) return true;

    // Caregiver attempting to access parent's custom imported music library
    final caregiverPermissions = ref.read(caregiverAccessProvider).permissions;
    final hasCustomMusicPermission = caregiverPermissions['custom_music'] ?? false;
    return hasCustomMusicPermission;
  }

  static void showCustomMusicRestrictedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Parent Permission Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Custom music imported from the parent\'s personal library can only be accessed when granted permission by the primary parent.\n\nYou have full access to all in-app online lullabies, white noise, and soothing sounds.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
