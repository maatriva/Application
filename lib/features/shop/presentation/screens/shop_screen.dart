import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/shared/widgets/bottom_navigation.dart';
import '../widgets/shop_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/category_list.dart';
import '../widgets/product_card.dart';
import '../widgets/empty_state_widget.dart';
import '../../provider/shop_provider.dart';
import '../../domain/product.dart';
import 'package:go_router/go_router.dart';

import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import 'package:maatriva/shared/widgets/caretaker_access_restricted_widget.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authNotifierProvider).session;
    final isCaregiver = authSession?.role == UserRole.caregiver;
    final perms = ref.watch(caregiverPermissionsProvider);
    final bool permsShop = !isCaregiver ||
        (perms['shop'] == true ||
            perms['shop_access'] == true ||
            perms['canViewShop'] == true);

    if (!permsShop) {
      return CaretakerAccessRestrictedWidget.restricted(
        sectionName: 'Shop',
        tabIndex: 4,
      );
    }

    final shopState = ref.watch(shopProvider);
    final shopNotifier = ref.read(shopProvider.notifier);
    final filteredProducts = shopNotifier.getFilteredProducts();

    final isSearchingOrFiltering =
        shopState.searchQuery.isNotEmpty ||
        shopState.selectedCategory != 'All' ||
        shopState.filter.selectedCategory != 'All' ||
        shopState.filter.minPrice > 0.0 ||
        shopState.filter.maxPrice < 200.0 ||
        shopState.filter.selectedRating > 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ShopHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Area with Filter button
            const SearchBarWidget(),

            // Dynamic Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.read(shopProvider.notifier).resetFilters();
                  ref.read(shopProvider.notifier).updateSearchQuery('');
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Offer banner (only show if not actively searching/filtering to keep screen spacious)
                    if (!isSearchingOrFiltering)
                      const SliverToBoxAdapter(child: FeaturedCarousel()),

                    // Categories selector banner
                    if (!isSearchingOrFiltering)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: const CategoryList(),
                        ),
                      ),

                    // Essentials Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSearchingOrFiltering
                                      ? 'Search Results'
                                      : 'Essentials',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${filteredProducts.length} items found',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.6,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Toggle layout buttons
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isGridView = true),
                                  child: Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: _isGridView
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: _isGridView
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 18.r,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isGridView = false),
                                  child: Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: !_isGridView
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.view_list_rounded,
                                      color: !_isGridView
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 18.r,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grid or List Products view
                    if (filteredProducts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: 'No Items Found',
                          description:
                              'We couldn\'t find any baby essentials matching your current query or filters.',
                          buttonText: 'Reset Filters',
                          onButtonPressed: () {
                            ref.read(shopProvider.notifier).resetFilters();
                            ref
                                .read(shopProvider.notifier)
                                .updateSearchQuery('');
                          },
                        ),
                      )
                    else if (_isGridView)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14.h,
                                crossAxisSpacing: 14.w,
                                childAspectRatio: 0.72,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = filteredProducts[index];
                            return ProductCard(product: product);
                          }, childCount: filteredProducts.length),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = filteredProducts[index];
                            return _buildProductListRow(context, product);
                          }, childCount: filteredProducts.length),
                        ),
                      ),
                    // Margin under items
                    SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildProductListRow(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        context.push('/shop/product-details', extra: product);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.04),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                product.imageUrl,
                width: 80.w,
                height: 80.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    product.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14.r),
                      SizedBox(width: 2.w),
                      Text(
                        '${product.rating}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${product.reviewsCount} reviews)',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Cart and Wishlist triggers
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(shopProvider.notifier).toggleWishlist(product.id);
                  },
                  child: Icon(
                    ref.read(shopProvider.notifier).isInWishlist(product.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        ref.read(shopProvider.notifier).isInWishlist(product.id)
                        ? Colors.red
                        : AppColors.textSecondary.withOpacity(0.4),
                    size: 20.r,
                  ),
                ),
                SizedBox(height: 14.h),
                GestureDetector(
                  onTap: () {
                    ref.read(shopProvider.notifier).addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF109F6E),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 14,
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
}
