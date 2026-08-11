import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../providers/music_provider.dart';
import 'album_art_widget.dart';

class MiniMusicPlayer extends ConsumerWidget {
  const MiniMusicPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final currentSong = musicState.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final progress = currentSong.duration.inSeconds > 0
        ? musicState.currentPosition.inSeconds / currentSong.duration.inSeconds
        : 0.0;

    return GestureDetector(
      onTap: () {
        context.push('/music/player');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.clayShadow,
          border: Border.all(
            color: AppColors.softTeal.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle top progress bar
              SizedBox(
                height: 3,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Album Art with small equalizer symbol
                    AlbumArtWidget(
                      colorKey: currentSong.albumArtColor,
                      size: 44,
                      borderRadius: 12,
                      isPlaying: musicState.isPlaying,
                    ),
                    const SizedBox(width: 12),

                    // Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controls
                    IconButton(
                      icon: Icon(
                        musicState.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      onPressed: () {
                        ref.read(musicProvider.notifier).togglePlayPause();
                      },
                    ),
                    if (musicState.activePlaylist != null)
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.textSecondary,
                          size: 26,
                        ),
                        onPressed: () {
                          ref.read(musicProvider.notifier).nextTrack();
                        },
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
