import 'package:flutter/material.dart';

class AlbumArtWidget extends StatelessWidget {
  final String colorKey;
  final double size;
  final double borderRadius;
  final bool isPlaying;
  final IconData? icon;

  const AlbumArtWidget({
    super.key,
    required this.colorKey,
    this.size = 60,
    this.borderRadius = 16,
    this.isPlaying = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Gradient gradient;
    IconData defaultIcon = icon ?? Icons.music_note_rounded;

    switch (colorKey) {
      case 'purple':
        gradient = const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'blue':
        gradient = const LinearGradient(
          colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'rose':
        gradient = const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'teal':
        gradient = const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'sunset':
        gradient = const LinearGradient(
          colors: [Color(0xFFf857a6), Color(0xFFff5858)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'indigo':
        gradient = const LinearGradient(
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'emerald':
        gradient = const LinearGradient(
          colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'mint':
        gradient = const LinearGradient(
          colors: [Color(0xFF80f3ec), Color(0xFF4cd7c2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'lavender':
      default:
        gradient = const LinearGradient(
          colors: [Color(0xFF9d85fc), Color(0xFFe299ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            defaultIcon,
            color: Colors.white.withOpacity(0.9),
            size: size * 0.45,
          ),
          if (isPlaying)
            Positioned(
              right: size * 0.1,
              bottom: size * 0.1,
              child: Container(
                padding: const EdgeInsets.all(4),
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
}
