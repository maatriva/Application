import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'custom_clock_time_picker.dart';

class DurationSelector extends StatelessWidget {
  final String selectedLabel;
  final ValueChanged<String> onSelected;
  final bool isCaregiver;

  const DurationSelector({
    super.key,
    required this.selectedLabel,
    required this.onSelected,
    this.isCaregiver = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> options = [
      '15 Mins',
      '30 Mins',
      '1 Hour',
      '4 Hours',
      '12 Hours',
      '24 Hours',
      'Custom',
    ];

    final isCustomSelected = !options.take(6).contains(selectedLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Decided Access Duration',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isCaregiver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(
                        'Set by Parent',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Caretaker Locked Notice Banner
        if (isCaregiver)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caretaker access strictly follows the timing interval decided by the primary parent.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Parent Clock-Type Set Duration Interactive Visual Card
        if (!isCaregiver)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: InkWell(
              onTap: () async {
                final customTime = await CustomClockTimePicker.show(
                  context,
                  initialLabel: selectedLabel,
                  onTimeSelected: (val) {
                    onSelected(val);
                  },
                );
                if (customTime != null && customTime.isNotEmpty) {
                  onSelected(customTime);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF651FFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLOCK DURATION SETTER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tap to adjust using visual clock dial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Set Clock',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF651FFF),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: Color(0xFF651FFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 6),

        // Quick Preset Bubbles
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final optionLabel = options[index];
              bool isSelected = false;

              if (optionLabel == 'Custom') {
                isSelected = isCustomSelected || selectedLabel.toLowerCase() == 'custom';
              } else {
                isSelected = selectedLabel.toLowerCase() == optionLabel.toLowerCase();
              }

              final displayTitle = (optionLabel == 'Custom' && isCustomSelected)
                  ? 'Clock'
                  : optionLabel.split(' ')[0];

              final displaySub = (optionLabel == 'Custom' && isCustomSelected)
                  ? selectedLabel
                  : (optionLabel.split(' ').length > 1 ? optionLabel.split(' ')[1].toLowerCase() : '');

              return GestureDetector(
                onTap: isCaregiver
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Timing limits are decided by the Parent and cannot be changed by Caretaker.'),
                            backgroundColor: const Color(0xFFE65100),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    : () async {
                        if (optionLabel == 'Custom') {
                          final customTime = await CustomClockTimePicker.show(
                            context,
                            initialLabel: selectedLabel,
                            onTimeSelected: (val) {
                              onSelected(val);
                            },
                          );
                          if (customTime != null && customTime.isNotEmpty) {
                            onSelected(customTime);
                          }
                        } else {
                          onSelected(optionLabel);
                        }
                      },
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 0.95,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 78,
                    height: 78,
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
                      color: isSelected ? null : (isCaregiver ? const Color(0xFFF5F3FA) : Colors.white),
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
                          if (optionLabel == 'Custom')
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: isSelected ? 14 : 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isCaregiver ? AppColors.textSecondary : AppColors.textPrimary),
                            ),
                          ),
                          if (displaySub.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              displaySub,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
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
