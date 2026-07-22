import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../provider/shop_provider.dart';

class CategoryList extends ConsumerWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final shopNotifier = ref.read(shopProvider.notifier);
    final activeCategory = shopState.selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Text(
            'Categories',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 90.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            physics: const BouncingScrollPhysics(),
            itemCount:
                shopState.categories.length + 1, // +1 for the 'All' option
            itemBuilder: (context, index) {
              if (index == 0) {
                // Render 'All' category option
                final isSelected = activeCategory == 'All';
                return _buildCategoryCard(
                  context,
                  isSelected: isSelected,
                  name: 'All Essentials',
                  icon: Icons.grid_view_rounded,
                  activeColor: AppColors.primary,
                  inactiveBgColor: const Color(0xFFF3EDFA),
                  inactiveIconColor: AppColors.primary,
                  onTap: () => shopNotifier.selectCategory('All'),
                );
              }

              final category = shopState.categories[index - 1];
              final isSelected = activeCategory == category.name;

              return _buildCategoryCard(
                context,
                isSelected: isSelected,
                name: category.name,
                icon: category.icon,
                activeColor: category.activeColor,
                inactiveBgColor: category.inactiveColor,
                inactiveIconColor: category.activeColor,
                onTap: () => shopNotifier.selectCategory(category.name),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required bool isSelected,
    required String name,
    required IconData icon,
    required Color activeColor,
    required Color inactiveBgColor,
    required Color inactiveIconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? activeColor
                : AppColors.primary.withOpacity(0.04),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppColors.primary.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular container for icon
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : inactiveBgColor,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : inactiveIconColor,
                size: 16.r,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
