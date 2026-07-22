import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../domain/product.dart';
import '../../provider/shop_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailsScreen({super.key, this.product, this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _quantity = 1;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Resolve product from extra or lookup by ID
    if (widget.product != null) {
      _currentProduct = widget.product!;
    } else {
      final pid = widget.productId ?? 'p1';
      final products = ref.read(shopProvider).products;
      _currentProduct = products.firstWhere(
        (p) => p.id == pid,
        orElse: () => products.first,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(
      shopProvider.select(
        (state) => state.wishlist.contains(_currentProduct.id),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable details content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Large Image
                  Hero(
                    tag: 'product_image_${_currentProduct.id}',
                    child: Container(
                      height: 380.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_currentProduct.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Product details container
                  Container(
                    transform: Matrix4.translationValues(0, -28.h, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32.r),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating & Category Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                _currentProduct.category.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${_currentProduct.rating}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '(${_currentProduct.reviewsCount} reviews)',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Name
                        Text(
                          _currentProduct.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Price & Quantity Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${_currentProduct.price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.divider,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                    child: Container(
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3EDFA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _quantity++);
                                    },
                                    child: Container(
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Divider
                        const Divider(color: AppColors.divider, thickness: 1.5),
                        SizedBox(height: 14.h),

                        // Description
                        Text(
                          'Description',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _currentProduct.description,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Tabs section
                        Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EDFA),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: const [
                              Tab(text: 'Features'),
                              Tab(text: 'Specifications'),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 130.h,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Features list
                              ListView.builder(
                                padding: EdgeInsets.only(top: 12.h),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _currentProduct.features.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 3.h,
                                          right: 8.w,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF109F6E),
                                          size: 14,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _currentProduct.features[index],
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Specs Map
                              ListView(
                                padding: EdgeInsets.only(top: 12.h),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: _currentProduct.specifications.entries
                                    .map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5.h,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              entry.value,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),

                        // Review items
                        if (_currentProduct.reviews.isNotEmpty) ...[
                          const Divider(
                            color: AppColors.divider,
                            thickness: 1.5,
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'Reviews (${_currentProduct.reviews.length})',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ..._currentProduct.reviews.map(
                            (rev) => Container(
                              margin: EdgeInsets.only(top: 12.h),
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rev.reviewerName,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        rev.date,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        Icons.star_rounded,
                                        color: index < rev.rating
                                            ? Colors.amber
                                            : Colors.grey[300],
                                        size: 14.r,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    rev.comment,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back and Wishlist Header overlays
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Circular back button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                // Circular Wishlist button
                GestureDetector(
                  onTap: () {
                    ref
                        .read(shopProvider.notifier)
                        .toggleWishlist(_currentProduct.id);
                  },
                  child: Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : AppColors.primary,
                      size: 20.r,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sticky purchase sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20.w,
                16.h,
                20.w,
                MediaQuery.of(context).padding.bottom + 16.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '\$${(_currentProduct.price * _quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(shopProvider.notifier)
                            .addToCart(_currentProduct, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added $_quantity of ${_currentProduct.name} to cart!',
                            ),
                            backgroundColor: const Color(0xFF109F6E),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
