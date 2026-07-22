import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../providers/music_provider.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/sleep_timer_sheet.dart';

class MusicPlayerScreen extends ConsumerStatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // If already playing, start rotation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(musicProvider).isPlaying) {
        _rotationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);
    final currentSong = musicState.currentSong;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Now Playing'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('No song selected')),
      );
    }

    // React to play state change
    if (musicState.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    final totalSeconds = currentSong.duration.inSeconds;
    final currentSeconds = musicState.currentPosition.inSeconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF8FE), Color(0xFFF3EDFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'NOW PLAYING',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.category,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        musicState.sleepTimerRemaining != null
                            ? Icons.timer_rounded
                            : Icons.timer_outlined,
                        color: musicState.sleepTimerRemaining != null
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const SleepTimerSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Rotating Vinyl Album Artwork Container
                      Center(
                        child: RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.12),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Stack(
                                children: [
                                  // Album Art
                                  AlbumArtWidget(
                                    colorKey: currentSong.albumArtColor,
                                    size: 240,
                                    borderRadius: 0,
                                    icon: Icons.music_note,
                                  ),
                                  // Grooves of Vinyl representation
                                  Center(
                                    child: Container(
                                      width: 210,
                                      height: 210,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.08),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.08),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Center Spindle Hole
                                  Center(
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: AppColors.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppColors.textPrimary,
                                            shape: BoxShape.circle,
                                          ),
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
                      const SizedBox(height: 36),

                      // Song Title, Artist & Favorite Icon Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.displayHeader.copyWith(
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong.artist,
                                  style: AppTypography.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              currentSong.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: currentSong.isFavorite
                                  ? Colors.red
                                  : AppColors.textSecondary,
                              size: 28,
                            ),
                            onPressed: () {
                              ref
                                  .read(musicProvider.notifier)
                                  .toggleFavorite(currentSong.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Countdown timer display if sleep timer is active
                      if (musicState.sleepTimerRemaining != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sleep Timer active: ${_formatDuration(musicState.sleepTimerRemaining!)}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Slider & Time display
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.divider,
                              trackHeight: 4,
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayColor: AppColors.primary.withOpacity(0.1),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: currentSeconds.toDouble().clamp(
                                0.0,
                                totalSeconds.toDouble(),
                              ),
                              min: 0,
                              max: totalSeconds.toDouble(),
                              onChanged: (value) {
                                ref
                                    .read(musicProvider.notifier)
                                    .seek(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(musicState.currentPosition),
                                  style: AppTypography.labelSmall,
                                ),
                                Text(
                                  _formatDuration(currentSong.duration),
                                  style: AppTypography.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Playback Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: musicState.isShuffle
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                            onPressed: () {
                              ref.read(musicProvider.notifier).toggleShuffle();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: AppColors.textPrimary,
                              size: 36,
                            ),
                            onPressed: () {
                              ref.read(musicProvider.notifier).previousTrack();
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(musicProvider.notifier)
                                  .togglePlayPause();
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF6E3DE0),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                musicState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: AppColors.textPrimary,
                              size: 36,
                            ),
                            onPressed: () {
                              ref.read(musicProvider.notifier).nextTrack();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.repeat_rounded,
                              color: musicState.isRepeat
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                            onPressed: () {
                              ref.read(musicProvider.notifier).toggleRepeat();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Speed & Volume controllers
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.divider.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Volume control row
                            Row(
                              children: [
                                const Icon(
                                  Icons.volume_down_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primary
                                          .withOpacity(0.7),
                                      inactiveTrackColor: AppColors.divider,
                                      trackHeight: 2,
                                      thumbColor: AppColors.primary,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 4,
                                      ),
                                    ),
                                    child: Slider(
                                      value: musicState.volume,
                                      onChanged: (vol) {
                                        ref
                                            .read(musicProvider.notifier)
                                            .setVolume(vol);
                                      },
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Playback Speed Toggle Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Playback Speed',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [0.5, 1.0, 1.5, 2.0].map((speed) {
                                    final isSelected =
                                        musicState.playbackSpeed == speed;
                                    return GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(musicProvider.notifier)
                                            .setPlaybackSpeed(speed);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${speed}x',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
