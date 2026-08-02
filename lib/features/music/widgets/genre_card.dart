import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../models/lullaby_genre.dart';

class GenreCard extends StatelessWidget {
  final LullabyGenre genre;
  final int trackCount;
  final bool isSelected;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.genre,
    required this.trackCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient(genre.colorKey, isSelected);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 155,
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _shadowColor(genre.colorKey).withOpacity(isSelected ? 0.35 : 0.12),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: isSelected
              ? null
              : Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji in frosted circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : _shadowColor(genre.colorKey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    genre.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                genre.name,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$trackCount tracks',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _gradient(String colorKey, bool selected) {
    if (!selected) {
      return LinearGradient(
        colors: [Colors.white, Colors.white.withOpacity(0.96)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    switch (colorKey) {
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF00b09b), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teal':
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'indigo':
        return const LinearGradient(
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rose':
        return const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF9472)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'lavender':
      default:
        return const LinearGradient(
          colors: [Color(0xFF9d85fc), Color(0xFFe299ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _shadowColor(String colorKey) {
    switch (colorKey) {
      case 'purple': return const Color(0xFF8E2DE2);
      case 'emerald': return const Color(0xFF00b09b);
      case 'teal': return const Color(0xFF11998e);
      case 'indigo': return const Color(0xFF4776E6);
      case 'rose': return const Color(0xFFFF416C);
      default: return const Color(0xFF9d85fc);
    }
  }
}
