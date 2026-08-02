import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../data/mock_genres.dart';
import '../models/lullaby_genre.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/music_access_helper.dart';
import '../widgets/album_art_widget.dart';
import '../widgets/featured_banner.dart';
import '../widgets/genre_card.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_card_horizontal.dart';
import 'playlist_screen.dart';

class MusicHomeScreen extends ConsumerStatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  ConsumerState<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends ConsumerState<MusicHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showSortMenu = false;

  final List<Map<String, String>> _playlists = [
    {'name': 'Favorites', 'desc': 'Your beloved sounds'},
    {'name': 'Newborn Sleep', 'desc': 'Heartbeats & womb mimicry'},
    {'name': 'Night Sleep', 'desc': 'Soothing nocturnal tunes'},
    {'name': 'Nap Time', 'desc': 'Gentle daytime ambience'},
    {'name': 'White Noise Collection', 'desc': 'Continuous static & noise'},
    {'name': 'Calming Sounds', 'desc': 'Deep meditational harmonics'},
    {'name': 'Classical Collection', 'desc': 'Mozart, Beethoven & Satie'},
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
    final isFiltered = musicState.activeGenre != null ||
        musicState.activeCategory != null ||
        musicState.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(musicState, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Featured Banner ──────────────────────────────────
                        if (!isFiltered) ...[
                          const SizedBox(height: 8),
                          const FeaturedBanner(),
                          const SizedBox(height: 20),
                        ],

                        // ── Genre Cards ──────────────────────────────────────
                        if (!_isSearching) ...[
                          _sectionHeader(
                            'Browse by Genre',
                            null,
                            subtitle: 'Tap to explore a collection',
                          ),
                          const SizedBox(height: 8),
                          _buildGenreCards(musicState, notifier),
                          const SizedBox(height: 20),
                        ],

                        // ── Active filter label ──────────────────────────────
                        if (isFiltered) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    musicState.activeGenre != null
                                        ? '${musicState.activeGenre} Collection'
                                        : musicState.activeCategory != null
                                            ? '${musicState.activeCategory} Collection'
                                            : 'Search Results',
                                    style: AppTypography.sectionTitle
                                        .copyWith(fontSize: 18),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.clearAllFilters();
                                    setState(() => _isSearching = false);
                                  },
                                  icon: const Icon(Icons.close_rounded,
                                      size: 14, color: AppColors.primary),
                                  label: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // ── Sort bar (only when browsing all) ────────────────
                        if (!isFiltered && !_isSearching)
                          _buildSortBar(musicState, notifier),

                        // ── When filtering: show flat song list ──────────────
                        if (isFiltered)
                          _buildFilteredList(musicState, notifier)
                        else ...[
                          // ── Favorites shelf ──────────────────────────────
                          if (musicState.favoriteSongs.isNotEmpty) ...[
                            _sectionHeader('❤️  Favorites', 'Favorites'),
                            const SizedBox(height: 8),
                            _buildHorizontalShelf(musicState.favoriteSongs),
                            const SizedBox(height: 20),
                          ],

                          // ── Recently Played shelf ────────────────────────
                          if (musicState.recentlyPlayed.isNotEmpty) ...[
                            _sectionHeader(
                                '🕐  Recently Played', null),
                            const SizedBox(height: 8),
                            _buildRecentlyPlayedShelf(
                                musicState, notifier),
                            const SizedBox(height: 20),
                          ],

                          // ── Recommended for Tonight ──────────────────────
                          if (_recommendedSongs(musicState.songs).isNotEmpty) ...[
                            _sectionHeader(
                              '✨  Recommended for Tonight',
                              null,
                              subtitle: 'Based on your listening habits',
                            ),
                            const SizedBox(height: 8),
                            _buildHorizontalShelf(
                              _recommendedSongs(musicState.songs),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Parent Custom Music Library ──────────────────────────────
                          if (musicState.songs.any((s) => s.isCustomParentSong)) ...[
                            _sectionHeader(
                              '🔒  Parent\'s Custom Music Library',
                              null,
                              subtitle: 'Imported by parent (Requires Parent Permission for Caregivers)',
                            ),
                            const SizedBox(height: 8),
                            _buildHorizontalShelf(
                              musicState.songs.where((s) => s.isCustomParentSong).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Empty Library State ──────────────────────────
                          if (musicState.songs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.divider.withOpacity(0.5),
                                  ),
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.music_off_outlined,
                                      size: 56,
                                      color: AppColors.textSecondary.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Music Available',
                                      style: AppTypography.sectionTitle.copyWith(fontSize: 18),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'All existing songs and music tracks have been removed.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Genre sections ───────────────────────────────
                          for (final genre in mockGenres)
                            _buildGenreSection(genre, musicState, notifier),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating mini player
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

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(MusicState musicState, MusicNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _isSearching
                ? _buildSearchField(notifier)
                : Text(
                    'Lullaby Library',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_rounded,
                  color: Colors.redAccent, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PlaylistScreen(playlistName: 'Favorites'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(MusicNotifier notifier) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppTypography.labelMedium,
        onChanged: (val) => ref.read(musicProvider.notifier).setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Songs, genres, artists…',
          hintStyle: AppTypography.labelSmall.copyWith(color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, size: 16,
                color: AppColors.textSecondary),
            onPressed: () {
              _searchController.clear();
              notifier.clearAllFilters();
              setState(() => _isSearching = false);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
      ),
    );
  }

  // ── Sort bar ──────────────────────────────────────────────────────────────
  Widget _buildSortBar(MusicState musicState, MusicNotifier notifier) {
    final labels = {
      SortMode.alphabetical: 'A–Z',
      SortMode.recentlyPlayed: 'Recent',
      SortMode.favorites: 'Favorites',
      SortMode.duration: 'Duration',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text('Sort by:', style: AppTypography.labelSmall),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: labels.entries.map((e) {
                  final selected = musicState.sortMode == e.key;
                  return GestureDetector(
                    onTap: () => notifier.setSortMode(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider.withOpacity(0.6),
                        ),
                        boxShadow: selected ? AppColors.softShadow : null,
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
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
        ],
      ),
    );
  }

  // ── Genre cards ────────────────────────────────────────────────────────────
  Widget _buildGenreCards(MusicState musicState, MusicNotifier notifier) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: mockGenres.length,
        itemBuilder: (context, i) {
          final genre = mockGenres[i];
          final count = musicState.songs
              .where((s) => s.genre == genre.name)
              .length;
          final isSelected = musicState.activeGenre == genre.name;
          return GenreCard(
            genre: genre,
            trackCount: count,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) {
                notifier.clearAllFilters();
              } else {
                notifier.setGenreFilter(genre.name);
              }
            },
          );
        },
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String? playlistName,
      {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.labelSmall),
                ],
              ],
            ),
          ),
          if (playlistName != null)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlaylistScreen(playlistName: playlistName),
                ),
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Horizontal shelf (song cards) ─────────────────────────────────────────
  Widget _buildHorizontalShelf(List<Song> songs) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: songs.length,
        itemBuilder: (_, i) => SongCardHorizontal(song: songs[i]),
      ),
    );
  }

  // ── Recently Played shelf (compact row cards) ─────────────────────────────
  Widget _buildRecentlyPlayedShelf(MusicState state, MusicNotifier notifier) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: state.recentlyPlayed.length,
        itemBuilder: (_, i) {
          final song = state.recentlyPlayed[i];
          final isCurrent = state.currentSong?.id == song.id;
          return GestureDetector(
            onTap: () {
              if (!MusicAccessHelper.canAccessSong(song, ref)) {
                MusicAccessHelper.showCustomMusicRestrictedDialog(context);
                return;
              }
              notifier.selectSong(song);
              context.push('/music/player');
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.divider.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  AlbumArtWidget(
                    colorKey: song.albumArtColor,
                    size: 40,
                    borderRadius: 10,
                    isPlaying: isCurrent && state.isPlaying,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 11,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.labelSmall.copyWith(fontSize: 9),
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
    );
  }

  // ── Recommended songs ─────────────────────────────────────────────────────
  List<Song> _recommendedSongs(List<Song> all) {
    final hour = DateTime.now().hour;
    final String genre;
    if (hour >= 19 || hour < 5) {
      genre = 'Classic Lullabies';
    } else if (hour >= 12 && hour < 17) {
      genre = 'Nature Sounds';
    } else {
      genre = 'Instrumental';
    }
    final primary = all.where((s) => s.genre == genre).take(4).toList();
    final rest = all.where((s) => s.isFavorite && s.genre != genre).take(2).toList();
    return [...primary, ...rest];
  }

  // ── Genre sections (one per genre) ────────────────────────────────────────
  Widget _buildGenreSection(
    LullabyGenre genre,
    MusicState musicState,
    MusicNotifier notifier,
  ) {
    final songs = musicState.songs
        .where((s) => s.genre == genre.name)
        .take(8)
        .toList();
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '${genre.emoji}  ${genre.name}',
          null,
          subtitle: genre.description,
        ),
        const SizedBox(height: 8),
        _buildHorizontalShelf(songs),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Filtered/search list ───────────────────────────────────────────────────
  Widget _buildFilteredList(MusicState musicState, MusicNotifier notifier) {
    final songs = musicState.filteredSongs;
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.music_off_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.25)),
              const SizedBox(height: 16),
              Text(
                'No music found',
                style: AppTypography.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search or genre filter.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  _searchController.clear();
                  notifier.clearAllFilters();
                  setState(() => _isSearching = false);
                },
                child: const Text('Browse Library',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text('${songs.length} tracks',
              style: AppTypography.labelSmall),
        ),
        _buildSortBar(musicState, notifier),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (_, i) => _buildSongListTile(songs[i], musicState, notifier),
        ),
      ],
    );
  }

  Widget _buildSongListTile(
      Song song, MusicState musicState, MusicNotifier notifier) {
    final isCurrent = musicState.currentSong?.id == song.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.divider.withOpacity(0.4),
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: AlbumArtWidget(
          colorKey: song.albumArtColor,
          size: 48,
          isPlaying: isCurrent && musicState.isPlaying,
          categoryIcon: _iconForCategory(song.category),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: isCurrent ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${song.artist} · ${_fmt(song.duration)}',
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
                    ? Colors.redAccent
                    : AppColors.textSecondary,
                size: 18,
              ),
              onPressed: () => notifier.toggleFavorite(song.id),
            ),
            IconButton(
              icon: Icon(
                isCurrent && musicState.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: () {
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
            ),
          ],
        ),
        onTap: () {
          if (!MusicAccessHelper.canAccessSong(song, ref)) {
            MusicAccessHelper.showCustomMusicRestrictedDialog(context);
            return;
          }
          notifier.selectSong(song);
          context.push('/music/player');
        },
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
