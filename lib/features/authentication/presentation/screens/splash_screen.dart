import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled Celestial Logo Area
            Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/MaatrivaFavicon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'MAATRIVA',
              style: GoogleFonts.outfit(
                textStyle: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'AI-POWERED SMART BABY MONITOR',
              style: GoogleFonts.outfit(
                textStyle: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 48.h),
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
