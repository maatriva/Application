import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../providers/music_provider.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/mini_player.dart';

class PlaylistScreen extends ConsumerWidget {
  final String playlistName;

  const PlaylistScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicState = ref.watch(musicProvider);
    final notifier = ref.read(musicProvider.notifier);

    // Get songs matching playlist
    final songs = notifier.getSongsForPlaylist(playlistName, musicState.songs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          playlistName,
          style: AppTypography.sectionTitle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Music in this Playlist',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent = musicState.currentSong?.id == song.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.divider.withOpacity(0.5),
                          ),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          children: [
                            AlbumArtWidget(
                              colorKey: song.albumArtColor,
                              size: 48,
                              isPlaying: isCurrent && musicState.isPlaying,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isCurrent
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: AppTypography.labelSmall,
                            ),
                            IconButton(
                              icon: Icon(
                                song.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: song.isFavorite
                                    ? Colors.red
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                notifier.toggleFavorite(song.id);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isCurrent && musicState.isPlaying
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              onPressed: () {
                                if (isCurrent) {
                                  notifier.togglePlayPause();
                                } else {
                                  notifier.selectSong(song);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniMusicPlayer(),
          ),
        ],
      ),
    );
  }
}
