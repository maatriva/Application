import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';

class DurationSelector extends StatelessWidget {
  final String selectedLabel;
  final ValueChanged<String> onSelected;

  const DurationSelector({
    super.key,
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> options = [
      '30 Mins',
      '1 Hour',
      '4 Hours',
      '12 Hours',
      '24 Hours',
      'Custom',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Temporary Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final label = options[index];
              final isSelected =
                  selectedLabel.toLowerCase() == label.toLowerCase();

              return GestureDetector(
                onTap: () => onSelected(label),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 0.95,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    height: 76,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, Color(0xFF906CF7)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.08),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label.split(' ')[0],
                            style: TextStyle(
                              fontSize: isSelected ? 15 : 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (label.split(' ').length > 1) ...[
                            const SizedBox(height: 1),
                            Text(
                              label.split(' ')[1].toLowerCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.85)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
