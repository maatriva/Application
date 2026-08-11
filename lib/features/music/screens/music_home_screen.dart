import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../widgets/baby_care_song_card.dart';
import '../widgets/mini_player.dart';
import '../widgets/parent_recording_editor_dialog.dart';
import '../widgets/parent_upload_dialog.dart';

class MusicHomeScreen extends ConsumerStatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  ConsumerState<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends ConsumerState<MusicHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAutoSleepModeInfo(BuildContext context, MusicState state, MusicNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF6B4EE6),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Sleep Assistant',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        state.isAutoSleepModeEnabled
                            ? 'Status: Active • Monitoring Baby Care'
                            : 'Status: Standby • Tap to Enable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: state.isAutoSleepModeEnabled
                              ? const Color(0xFF2E7D32)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'How Auto Sleep Mode Works:',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _criteriaItem(Icons.mic_rounded, 'Cry Detection', 'Detects baby crying frequency and triggers soothing lullaby.'),
            _criteriaItem(Icons.sentiment_satisfied_alt_rounded, 'Baby Mood', 'Adapts acoustic tempo to calm baby\'s restless energy.'),
            _criteriaItem(Icons.bedtime_rounded, 'Sleep Stage', 'Transitions from gentle melody to deep womb noise during sleep.'),
            _criteriaItem(Icons.smart_toy_rounded, 'AI Recommendation', 'Learns which parent voice or lullaby works best for your baby.'),
            _criteriaItem(Icons.schedule_rounded, 'Time of Day', 'Adjusts volume and spectral frequencies according to nap or night time.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  notifier.toggleAutoSleepMode();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isAutoSleepModeEnabled
                      ? Colors.grey.shade300
                      : const Color(0xFF6B4EE6),
                  foregroundColor: state.isAutoSleepModeEnabled
                      ? AppColors.textPrimary
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  state.isAutoSleepModeEnabled ? 'Disable Auto Sleep Mode' : 'Enable Auto Sleep Mode',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _criteriaItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B4EE6)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicProvider);
    final notifier = ref.read(musicProvider.notifier);
    final parentRecordingsCount = musicState.songs.where((s) => s.isCustomParentSong).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(musicState, notifier),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => notifier.refreshLibrary(),
                    color: const Color(0xFF6B4EE6),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // ── TOP THREE BABY-CARE ACTION CARDS ────────────────
                          _buildTopActionCards(musicState, notifier, parentRecordingsCount),

                          const SizedBox(height: 24),

                          // ── ALL LULLABIES SECTION HEADER & FILTERS ──────────
                          _buildAllLullabiesHeader(musicState, notifier),

                          const SizedBox(height: 12),

                          // ── MUSIC LIST (CLEAN BABY-CARE CARDS) ──────────────
                          _buildMusicList(musicState, notifier),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Simplified Mini Player
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

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(MusicState musicState, MusicNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isSearching
                ? _buildSearchField(notifier)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Baby Sleep Assistant',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Soft, calming sounds & parent voice recordings',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!_isSearching) ...[
            GestureDetector(
              onTap: () => showParentCustomLullabyDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB2EBF2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF00838F),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+ Song',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00838F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isSearching = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
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
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B4EE6).withOpacity(0.4)),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 13),
        onChanged: (val) => notifier.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search lullabies or parent recordings...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6B4EE6)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
            onPressed: () {
              _searchController.clear();
              notifier.clearAllFilters();
              setState(() => _isSearching = false);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }

  // ── TOP THREE ACTION CARDS ────────────────────────────────────────────────
  Widget _buildTopActionCards(MusicState musicState, MusicNotifier notifier, int parentRecordingsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. AUTO SLEEP MODE CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: musicState.isAutoSleepModeEnabled
                    ? const Color(0xFF6B4EE6)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4EE6).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF6B4EE6),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto Sleep Mode',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: musicState.isAutoSleepModeEnabled
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: musicState.isAutoSleepModeEnabled
                                              ? Colors.green.shade600
                                              : Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'AI Sleep Assistant ${musicState.isAutoSleepModeEnabled ? "Active" : "Standby"}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: musicState.isAutoSleepModeEnabled
                                                ? Colors.green.shade800
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6B4EE6), size: 20),
                      onPressed: () => _showAutoSleepModeInfo(context, musicState, notifier),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Automatically plays the most suitable lullaby based on your baby\'s mood, crying, sleep stage and AI recommendations.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          notifier.toggleAutoSleepMode();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !musicState.isAutoSleepModeEnabled
                                    ? 'Enabled Auto Sleep Mode • AI Monitoring Cry & Sleep Stage'
                                    : 'Auto Sleep Mode Paused',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF6B4EE6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(
                          musicState.isAutoSleepModeEnabled
                              ? Icons.check_circle_rounded
                              : Icons.play_circle_filled_rounded,
                          size: 18,
                        ),
                        label: Text(
                          musicState.isAutoSleepModeEnabled ? 'Auto Mode Active' : 'Enable Auto',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: musicState.isAutoSleepModeEnabled
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF6B4EE6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ROW WITH CARDS 2 & 3
          Row(
            children: [
              // 2. RECORD LULLABY CARD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFFFD1DC), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Color(0xFFD81B60),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Record Parent Voice',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record your own voice, stories or lullabies for your baby.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => ParentRecordingEditorDialog.show(context),
                          icon: const Icon(Icons.mic_rounded, size: 14),
                          label: const Text(
                            'Start Recording',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD81B60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 3. PARENT'S MELODY VAULT CARD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFB2EBF2), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.folder_special_rounded,
                              color: Color(0xFF00838F),
                              size: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$parentRecordingsCount Tracks',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00838F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Parent's Melody Vault",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your private lullabies, gallery songs & recordings.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => showParentCustomLullabyDialog(context, ref),
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 13),
                              label: const Text(
                                '+ Add Song',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00838F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              notifier.setActiveFilterTab('Parent Recordings');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Opened Parent's Melody Vault"),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF00838F),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFB2EBF2)),
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                color: Color(0xFF00838F),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ALL LULLABIES HEADER & FILTER TABS ─────────────────────────────────────
  Widget _buildAllLullabiesHeader(MusicState musicState, MusicNotifier notifier) {
    final filterTabs = [
      'AI Recommendation',
      'Recently Played',
      'Favorites',
      'Parent Recordings',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'All Lullabies',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${musicState.filteredSongs.length} tracks',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4EE6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Recommended calming sounds for your baby.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterTabs.map((tab) {
                final isSelected = musicState.activeFilterTab == tab;

                return GestureDetector(
                  onTap: () => notifier.setActiveFilterTab(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6B4EE6) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6B4EE6) : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6B4EE6).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── MUSIC LIST ─────────────────────────────────────────────────────────────
  Widget _buildMusicList(MusicState musicState, MusicNotifier notifier) {
    final songs = musicState.filteredSongs;

    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.nightlight_round, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No lullabies found in this filter',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => notifier.setActiveFilterTab('AI Recommendation'),
                child: const Text('Show AI Recommendations', style: TextStyle(color: Color(0xFF6B4EE6))),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: songs.map((song) => BabyCareSongCard(song: song)).toList(),
    );
  }
}
