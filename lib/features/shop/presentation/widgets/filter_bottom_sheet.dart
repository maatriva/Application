import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../domain/product.dart';
import '../../provider/shop_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String _selectedCategory;
  late double _minPrice;
  late double _maxPrice;
  late double _selectedRating;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(shopProvider).filter;
    _selectedCategory = filter.selectedCategory;
    _minPrice = filter.minPrice;
    _maxPrice = filter.maxPrice;
    _selectedRating = filter.selectedRating;
    _sortBy = filter.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.read(shopProvider).categories;
    final sortOptions = [
      'Popular',
      'Newest',
      'Lowest Price',
      'Highest Price',
      'Highest Rated',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters & Sort',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _minPrice = 0.0;
                      _maxPrice = 200.0;
                      _selectedRating = 0.0;
                      _sortBy = 'Popular';
                    });
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Sort Section
            _buildSectionTitle('Sort By'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: sortOptions.map((opt) {
                final isSelected = _sortBy == opt;
                return GestureDetector(
                  onTap: () => setState(() => _sortBy = opt),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            // Price Section
            _buildSectionTitle('Price Range'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_minPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '\$${_maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0.0,
              max: 200.0,
              divisions: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withOpacity(0.1),
              onChanged: (RangeValues vals) {
                setState(() {
                  _minPrice = vals.start;
                  _maxPrice = vals.end;
                });
              },
            ),
            SizedBox(height: 16.h),
            // Categories Filter section
            _buildSectionTitle('Filter Category'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildCategoryButton('All'),
                ...categories.map((cat) => _buildCategoryButton(cat.name)),
              ],
            ),
            SizedBox(height: 20.h),
            // Rating filter section
            _buildSectionTitle('Minimum Rating'),
            Row(
              children: List.generate(5, (index) {
                final ratingVal = index + 1.0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = _selectedRating == ratingVal
                          ? 0.0
                          : ratingVal;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedRating >= ratingVal
                          ? Colors.amber.withOpacity(0.15)
                          : Colors.white,
                      border: Border.all(
                        color: _selectedRating >= ratingVal
                            ? Colors.amber
                            : AppColors.divider,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: _selectedRating >= ratingVal
                              ? Colors.amber
                              : Colors.grey[400],
                          size: 16.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$ratingVal+',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _selectedRating >= ratingVal
                                ? Colors.amber[800]
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 28.h),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(shopProvider.notifier)
                          .applyFilter(
                            ProductFilter(
                              selectedCategory: _selectedCategory,
                              minPrice: _minPrice,
                              maxPrice: _maxPrice,
                              selectedRating: _selectedRating,
                              sortBy: _sortBy,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String categoryName) {
    final isSelected = _selectedCategory == categoryName;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = categoryName),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
