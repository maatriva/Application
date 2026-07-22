import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../providers/music_provider.dart';

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final isTimerActive = musicState.sleepTimerRemaining != null;

    final timerOptions = [
      {'label': '10 Minutes', 'duration': const Duration(minutes: 10)},
      {'label': '20 Minutes', 'duration': const Duration(minutes: 20)},
      {'label': '30 Minutes', 'duration': const Duration(minutes: 30)},
      {'label': '45 Minutes', 'duration': const Duration(minutes: 45)},
      {'label': '1 Hour', 'duration': const Duration(hours: 1)},
      {
        'label': 'Until Baby Sleeps (Demo: 5s)',
        'duration': const Duration(seconds: 5),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configure Sleep Timer',
                style: AppTypography.sectionTitle.copyWith(fontSize: 20),
              ),
              if (isTimerActive)
                TextButton(
                  onPressed: () {
                    ref.read(musicProvider.notifier).cancelSleepTimer();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sleep timer cancelled'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Cancel Timer',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically stop lullabies when the countdown runs out.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Options List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timerOptions.length,
              itemBuilder: (context, index) {
                final option = timerOptions[index];
                final label = option['label'] as String;
                final duration = option['duration'] as Duration;

                return GestureDetector(
                  onTap: () {
                    ref.read(musicProvider.notifier).setSleepTimer(duration);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timer set for $label'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.divider.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
