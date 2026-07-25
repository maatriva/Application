import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class HealthHeader extends ConsumerWidget implements PreferredSizeWidget {
  const HealthHeader({super.key});

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final months = (difference.inDays / 30.4).floor();
    if (months < 1) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks old';
    }
    if (months >= 12) {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year' + (years > 1 ? 's' : '') + ' old';
      }
      return '$years yr $remainingMonths mo old';
    }
    return '$months months old';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    final babyName = baby?.name ?? 'Baby';
    final babyAge = baby != null ? _calculateAge(baby.birthDate) : 'Monitoring';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: baby?.photoUrl != null && baby!.photoUrl!.isNotEmpty
                    ? Image.network(
                        baby.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.face_retouching_natural_outlined,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.face_retouching_natural_outlined,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  babyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  babyAge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar date selector (mocked)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share health report (mocked)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
