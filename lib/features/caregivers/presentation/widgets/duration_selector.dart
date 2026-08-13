import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'flip_clock_duration_selector.dart';

/// Duration Selector Widget for Caregiver Access setup.
/// Features the interactive 3-column Flip Clock duration selector.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caregiver Access Duration',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isCaregiver)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 14.r, color: const Color(0xFFE65100)),
                      SizedBox(width: 4.w),
                      Text(
                        'Set by Parent',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
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

        if (isCaregiver)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18.r, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Caretaker access strictly follows the timing interval decided by the primary parent.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: 8.h),

        // Premium Flip Clock Duration Selector Widget
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: FlipClockDurationSelector(
            title: 'ACCESS DURATION',
            initialDurationLabel: selectedLabel,
            isCaregiverLocked: isCaregiver,
            onDurationChanged: (newLabel) {
              onSelected(newLabel);
            },
          ),
        ),
      ],
    );
  }
}
