import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../provider/shop_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/product_card.dart';

import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';
import 'package:maatriva/shared/widgets/caretaker_access_restricted_widget.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final products = shopState.products;
    final wishlistIds = shopState.wishlist;

    // Filter products that exist in wishlist
    final wishlistProducts = products
        .where((p) => wishlistIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 56.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'My Favorites',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: wishlistProducts.isEmpty
          ? EmptyStateWidget(
              icon: Icons.favorite_border_rounded,
              title: 'Your Wishlist is Empty',
              description:
                  'Save products you like to your favorites so you can easily find them later and add them to your crib setup.',
              buttonText: 'Browse Shop',
              onButtonPressed: () => context.pop(),
            )
          : SafeArea(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.72,
                ),
                itemCount: wishlistProducts.length,
                itemBuilder: (context, index) {
                  final product = wishlistProducts[index];
                  return ProductCard(product: product);
                },
              ),
            ),
    );
  }
}
