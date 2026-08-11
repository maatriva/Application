import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/music_access_helper.dart';
import 'album_art_widget.dart';

class BabyCareSongCard extends ConsumerWidget {
  final Song song;

  const BabyCareSongCard({
    super.key,
    required this.song,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final notifier = ref.read(musicProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final isCaregiver = authState.session?.role == UserRole.caregiver;
    final isCurrent = musicState.currentSong?.id == song.id;
    final isPlaying = isCurrent && musicState.isPlaying;

    // AI Badge or Type Badge
    String? badgeText = song.aiBadge;
    if (song.isCustomParentSong) {
      badgeText = 'Parent Recording';
    }

    Color badgeBg = const Color(0xFFEDE7F6);
    Color badgeColor = const Color(0xFF6B4EE6);
    IconData badgeIcon = Icons.auto_awesome_rounded;

    if (badgeText != null) {
      if (badgeText.contains('Crying')) {
        badgeBg = const Color(0xFFFFF3E0);
        badgeColor = const Color(0xFFE65100);
        badgeIcon = Icons.child_care_rounded;
      } else if (badgeText.contains('Deep Sleep') || badgeText.contains('Sleeping')) {
        badgeBg = const Color(0xFFE8EAF6);
        badgeColor = const Color(0xFF3F51B5);
        badgeIcon = Icons.nights_stay_rounded;
      } else if (badgeText.contains('Parent')) {
        badgeBg = const Color(0xFFFCE4EC);
        badgeColor = const Color(0xFFC2185B);
        badgeIcon = Icons.favorite_rounded;
      }
    }

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary
                : AppColors.softTeal.withValues(alpha: 0.35),
            width: isCurrent ? 1.8 : 1.0,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.clayShadow,
        ),
        child: Row(
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AlbumArtWidget(
                colorKey: song.albumArtColor,
                size: 64,
                borderRadius: 18,
                isPlaying: isPlaying,
              ),
            ),

            const SizedBox(width: 14),

            // Main Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI / Type Badge if present
                  if (badgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 11, color: badgeColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              badgeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Title
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? const Color(0xFF6B4EE6) : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Subtitle & Duration & Type
                  Row(
                    children: [
                      Text(
                        _formatDuration(song.duration),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          song.category.isNotEmpty ? song.category : 'Lullaby',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button for Custom Parent Songs
            if (song.isCustomParentSong && !isCaregiver)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Delete "${song.title}"?'),
                      content: const Text('Are you sure you want to delete this track from your Parent\'s Melody Vault?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            notifier.deleteCustomSong(song.id);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${song.title}" from library.'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Favorite Button
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? const Color(0xFFE91E63) : Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () {
                notifier.toggleFavorite(song.id);
              },
            ),

            // Play / Pause Button
            GestureDetector(
              onTap: () {
                if (!MusicAccessHelper.canAccessSong(song, ref)) {
                  MusicAccessHelper.showCustomMusicRestrictedDialog(context);
                  return;
                }
                if (isCurrent) {
                  notifier.togglePlayPause();
                } else {
                  notifier.selectSong(song);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFF6B4EE6) : const Color(0xFFEDE7F6),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B4EE6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isCurrent ? Colors.white : const Color(0xFF6B4EE6),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
