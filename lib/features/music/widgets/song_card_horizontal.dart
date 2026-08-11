import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/music_access_helper.dart';
import 'album_art_widget.dart';

/// Compact vertical card used in horizontal-scrolling shelves.
class SongCardHorizontal extends ConsumerWidget {
  final Song song;
  final bool showDuration;

  const SongCardHorizontal({
    super.key,
    required this.song,
    this.showDuration = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final notifier = ref.read(musicProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final isCurrent = musicState.currentSong?.id == song.id;
    final isPlaying = isCurrent && musicState.isPlaying;

    return GestureDetector(
      onTap: () {
        if (!MusicAccessHelper.canAccessSong(song, ref)) {
          MusicAccessHelper.showCustomMusicRestrictedDialog(context);
          return;
        }
        notifier.selectSong(song);
        context.push('/music/player');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.18)
                  : const Color(0xFF5D2EC0).withOpacity(0.06),
              blurRadius: isCurrent ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withOpacity(0.35)
                : AppColors.divider.withOpacity(0.5),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: AlbumArtWidget(
                colorKey: song.albumArtColor,
                size: 148,
                borderRadius: 0,
                isPlaying: isPlaying,
                categoryIcon: _iconForCategory(song.category),
              ),
            ),

            // Metadata
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 12,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showDuration)
                        Text(
                          _fmt(song.duration),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      Row(
                        children: [
                          if (song.isCustomParentSong && !isCaregiver)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Custom Lullaby?'),
                                    content: Text('Are you sure you want to delete "${song.title}" from your library?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          notifier.deleteCustomSong(song.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red.shade400,
                                  size: 16,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => notifier.toggleFavorite(song.id),
                            child: Icon(
                              song.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: song.isFavorite
                                  ? Colors.redAccent
                                  : AppColors.textSecondary.withOpacity(0.5),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Rain Sounds': return Icons.water_drop_rounded;
      case 'Ocean Waves': return Icons.waves_rounded;
      case 'Nature Sounds': return Icons.forest_rounded;
      case 'White Noise': return Icons.blur_on_rounded;
      case 'Heartbeat Sounds': return Icons.favorite_rounded;
      case 'Meditation': return Icons.self_improvement_rounded;
      case 'Classical': return Icons.piano_rounded;
      case 'Piano': return Icons.piano_rounded;
      case 'Instrumental': return Icons.music_note_rounded;
      default: return Icons.queue_music_rounded;
    }
  }
}
