import 'package:flutter/material.dart';

/// Renders a gradient-filled card / circle that serves as album artwork.
/// Each [colorKey] maps to a beautiful two-stop gradient.  Pass [categoryIcon]
/// to show a domain-specific icon instead of the default music note.
class AlbumArtWidget extends StatelessWidget {
  final String colorKey;
  final double size;
  final double borderRadius;
  final bool isPlaying;
  final IconData? icon;
  final IconData? categoryIcon;

  const AlbumArtWidget({
    super.key,
    required this.colorKey,
    this.size = 60,
    this.borderRadius = 16,
    this.isPlaying = false,
    this.icon,
    this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient(colorKey);
    final displayIcon =
        icon ?? categoryIcon ?? Icons.music_note_rounded;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial highlight
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  center: const Alignment(-0.4, -0.4),
                  radius: 0.7,
                ),
              ),
            ),
          ),
          Icon(
            displayIcon,
            color: Colors.white.withOpacity(0.92),
            size: size * 0.42,
          ),
          if (isPlaying)
            Positioned(
              right: size * 0.08,
              bottom: size * 0.08,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.equalizer_rounded,
                  color: Color(0xFF6E3DE0),
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static LinearGradient _gradient(String colorKey) {
    switch (colorKey) {
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'blue':
        return const LinearGradient(
          colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'rose':
        return const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF9472)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'teal':
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'sunset':
        return const LinearGradient(
          colors: [Color(0xFFf857a6), Color(0xFFff5858)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'indigo':
        return const LinearGradient(
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'mint':
        return const LinearGradient(
          colors: [Color(0xFF43C6AC), Color(0xFF4cd7c2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case 'lavender':
      default:
        return const LinearGradient(
          colors: [Color(0xFF9d85fc), Color(0xFFe299ff)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
    }
  }
}
