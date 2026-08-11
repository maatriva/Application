import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import '../providers/music_provider.dart';
import 'admin_upload_dialog.dart';
import 'parent_upload_dialog.dart';

/// Animated hero banner at the top of the music home screen.
/// Shows a time-of-day–based recommendation and a quick-play button.
class FeaturedBanner extends ConsumerStatefulWidget {
  const FeaturedBanner({super.key});

  @override
  ConsumerState<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends ConsumerState<FeaturedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  ({
    String title,
    String subtitle,
    String badge,
    String genre,
    List<Color> colors,
  }) get _content {
    final hour = DateTime.now().hour;
    if (hour >= 20 || hour < 6) {
      return (
        title: 'Bedtime\nSerenade 🌙',
        subtitle: 'Calming lullabies to help your baby\ndrift into deep, restful sleep.',
        badge: 'NIGHT ROUTINE RECOMMENDED',
        genre: 'Classic Lullabies',
        colors: [const Color(0xFF1A1B4B), const Color(0xFF2E1065)],
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        title: 'Nap Time\nGoodness ☀️',
        subtitle: 'Soft sounds to guide your baby\ninto a peaceful afternoon slumber.',
        badge: 'NAP TIME SPECIAL',
        genre: 'Nature Sounds',
        colors: [const Color(0xFF00533A), const Color(0xFF00b09b)],
      );
    } else {
      return (
        title: 'Morning\nCalm 🌸',
        subtitle: 'Start your day gently with soothing\nsounds for a happy, settled baby.',
        badge: 'MORNING COLLECTION',
        genre: 'Instrumental',
        colors: [const Color(0xFF4A0080), const Color(0xFFAA4CE0)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(musicProvider.notifier);
    final musicState = ref.watch(musicProvider);
    final authState = ref.watch(authNotifierProvider);
    final isParent = authState.session?.role == UserRole.parent;
    final isAdmin = authState.session?.role == UserRole.admin ||
        authState.session?.email.toLowerCase() == 'admin@maatriva.com';
    final c = _content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: c.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: c.colors.last.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative blurred circles
                Positioned(
                  top: -20,
                  right: -10,
                  child: _glow(80, c.colors.last.withOpacity(0.25)),
                ),
                Positioned(
                  bottom: -30,
                  left: 60,
                  child: _glow(100, Colors.white.withOpacity(0.06)),
                ),
                Positioned(
                  top: 30,
                  right: 60,
                  child: _glow(50, Colors.white.withOpacity(
                    0.04 + _shimmerAnim.value * 0.06,
                  )),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          c.badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Headline
                      Text(
                        c.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.82),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons row
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (musicState.songs.isEmpty) {
                                showAdminUploadDialog(context, ref);
                                return;
                              }
                              final song = musicState.songs.firstWhere(
                                (s) => s.genre == c.genre,
                                orElse: () => musicState.songs.first,
                              );
                              notifier.selectSong(song);
                              context.push('/music/player');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: c.colors.last,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Play Now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: c.colors.last,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isParent)
                            GestureDetector(
                              onTap: () => showParentCustomLullabyDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Add Song from Gallery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (isAdmin)
                            GestureDetector(
                              onTap: () => showAdminUploadDialog(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Upload Music (Admin)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
}
