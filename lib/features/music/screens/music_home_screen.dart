import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../providers/music_provider.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/mini_player.dart';
import 'playlist_screen.dart';

class MusicHomeScreen extends ConsumerStatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  ConsumerState<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends ConsumerState<MusicHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _categories = [
    'All',
    'Lullabies',
    'White Noise',
    'Nature Sounds',
    'Rain Sounds',
    'Heartbeat Sounds',
    'Ocean Waves',
    'Meditation',
    'Classical',
    'Piano',
    'Instrumental',
    'Sleep Stories',
  ];

  final List<Map<String, String>> _playlists = [
    {'name': 'Favorites', 'desc': 'Your beloved sounds'},
    {'name': 'Newborn Sleep', 'desc': 'Heartbeats & womb mimicry'},
    {'name': 'Night Sleep', 'desc': 'Soothing nocturnal tunes'},
    {'name': 'Nap Time', 'desc': 'Gentle daytime ambience'},
    {
      'name': 'White Noise Collection',
      'desc': 'Continuous static & pink noise',
    },
    {'name': 'Calming Sounds', 'desc': 'Deep meditational harmonics'},
    {'name': 'Classical Collection', 'desc': 'Mozart, Beethoven & Chopin'},
    {'name': 'Nature Collection', 'desc': 'Rain, forest & sea breezes'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);
    final notifier = ref.read(musicProvider.notifier);

    // Apply filtering based on provider state
    final filteredSongs = musicState.filteredSongs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Premium Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => context.go('/'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isSearching
                            ? Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: AppTypography.labelMedium,
                                  onChanged: (val) {
                                    notifier.setSearchQuery(val);
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search lullabies, white noise...',
                                    hintStyle: AppTypography.labelSmall
                                        .copyWith(color: Colors.grey),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        notifier.setSearchQuery('');
                                        setState(() {
                                          _isSearching = false;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      top: 8,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                'Baby Music',
                                style: AppTypography.sectionTitle.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                      ),
                      if (!_isSearching) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaylistScreen(
                                  playlistName: 'Favorites',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Scrollable library feed
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured sleep collection banner
                        if (!_isSearching &&
                            musicState.activeCategory == null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8143D1),
                                    Color(0xFF6E3DE0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: const Text(
                                      'SLEEP TIME SELECTION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Relaxing lullabies for peaceful sleep',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Help your baby drift into a restful sleep with acoustic guitars, gentle flutes and brainwave frequencies.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      // Find first lullaby and play it
                                      final firstLullaby = musicState.songs
                                          .firstWhere(
                                            (s) => s.category == 'Lullabies',
                                            orElse: () =>
                                                musicState.songs.first,
                                          );
                                      notifier.selectSong(firstLullaby);
                                      context.push('/music/player');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.primary,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Play Now',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Horizontally scrolling category chips
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categories.map((cat) {
                                final isSelected =
                                    (cat == 'All' &&
                                        musicState.activeCategory == null) ||
                                    (musicState.activeCategory == cat);

                                return GestureDetector(
                                  onTap: () {
                                    notifier.setCategoryFilter(cat);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.divider.withOpacity(
                                                0.5,
                                              ),
                                      ),
                                      boxShadow: AppColors.softShadow,
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
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
                          ),
                        ),

                        // Predefined playlists bento layout
                        if (!_isSearching &&
                            musicState.activeCategory == null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Predefined Playlists',
                              style: AppTypography.sectionTitle.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 16),
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final pl = _playlists[index];
                                final name = pl['name']!;
                                final desc = pl['desc']!;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PlaylistScreen(playlistName: name),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 170,
                                    margin: const EdgeInsets.only(
                                      right: 12,
                                      bottom: 8,
                                      top: 4,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: AppColors.softShadow,
                                      border: Border.all(
                                        color: AppColors.divider.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight
                                                .withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.playlist_play_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelMedium
                                                  .copyWith(fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              desc,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelSmall
                                                  .copyWith(fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Recently played shelf
                        if (!_isSearching &&
                            musicState.activeCategory == null &&
                            musicState.recentlyPlayed.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Recently Played',
                              style: AppTypography.sectionTitle.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 16),
                              itemCount: musicState.recentlyPlayed.length,
                              itemBuilder: (context, index) {
                                final song = musicState.recentlyPlayed[index];
                                final isCurrent =
                                    musicState.currentSong?.id == song.id;

                                return GestureDetector(
                                  onTap: () {
                                    notifier.selectSong(song);
                                    context.push('/music/player');
                                  },
                                  child: Container(
                                    width: 190,
                                    margin: const EdgeInsets.only(
                                      right: 12,
                                      bottom: 6,
                                      top: 4,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: AppColors.softShadow,
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.primary.withOpacity(0.3)
                                            : AppColors.divider.withOpacity(
                                                0.4,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AlbumArtWidget(
                                          colorKey: song.albumArtColor,
                                          size: 36,
                                          borderRadius: 10,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                song.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.labelMedium
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                song.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.labelSmall
                                                    .copyWith(fontSize: 8),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Main Library list
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                musicState.activeCategory != null
                                    ? '${musicState.activeCategory} Collection'
                                    : 'Music Library',
                                style: AppTypography.sectionTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${filteredSongs.length} tracks',
                                style: AppTypography.labelSmall,
                              ),
                            ],
                          ),
                        ),

                        if (filteredSongs.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.music_off_outlined,
                                    size: 56,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No matching music available',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                      notifier.setCategoryFilter(null);
                                      setState(() {
                                        _isSearching = false;
                                      });
                                    },
                                    child: const Text(
                                      'Browse Library',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredSongs.length,
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
                              final isCurrent =
                                  musicState.currentSong?.id == song.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppColors.primary.withOpacity(0.4)
                                        : AppColors.divider.withOpacity(0.4),
                                  ),
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: AlbumArtWidget(
                                    colorKey: song.albumArtColor,
                                    size: 48,
                                    isPlaying:
                                        isCurrent && musicState.isPlaying,
                                  ),
                                  title: Text(
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
                                  subtitle: Text(
                                    '${song.artist} • ${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, "0")}',
                                    style: AppTypography.labelSmall,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          song.isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: song.isFavorite
                                              ? Colors.red
                                              : AppColors.textSecondary,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          notifier.toggleFavorite(song.id);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isCurrent && musicState.isPlaying
                                              ? Icons
                                                    .pause_circle_filled_rounded
                                              : Icons
                                                    .play_circle_filled_rounded,
                                          color: AppColors.primary,
                                          size: 26,
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
                                  onTap: () {
                                    notifier.selectSong(song);
                                    context.push('/music/player');
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Mini music player floating indicator
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniMusicPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}
