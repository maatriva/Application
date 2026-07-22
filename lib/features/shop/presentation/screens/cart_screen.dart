import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../provider/shop_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../../domain/product.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isPromoApplied = false;
  double _promoDiscount = 0.0;
  String? _promoError;

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'MAATRIVA20' || code == 'BABYFIRST') {
      setState(() {
        _isPromoApplied = true;
        _promoDiscount = 0.20; // 20% Discount
        _promoError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied: 20% discount!'),
          backgroundColor: Color(0xFF109F6E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (code.isEmpty) {
      setState(() {
        _promoError = 'Please enter a code';
      });
    } else {
      setState(() {
        _promoError = 'Invalid promo code';
        _isPromoApplied = false;
        _promoDiscount = 0.0;
      });
    }
  }

  void _showCheckoutDialog(double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.h,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F5EE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF109F6E),
                    size: 40,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Order Placed Successfully!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Thank you for shopping with Maatriva. Your total of \$${total.toStringAsFixed(2)} has been processed. We will monitor your nursery setup and shipping detail.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(shopProvider.notifier).clearCart();
                    Navigator.pop(context); // Close dialog
                    context.pop(); // Go back to shop catalog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text(
                    'Back to Shop',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final shopNotifier = ref.read(shopProvider.notifier);
    final cartItems = shopState.cart;

    // Delivery and Pricing Calculations
    final subtotal = shopNotifier.cartTotal;
    final deliveryFee = subtotal > 50.0 ? 0.0 : 5.00;
    final discountAmount = subtotal * _promoDiscount;
    final total = subtotal + deliveryFee - discountAmount;

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
          'My Shopping Cart',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Your Cart is Empty',
              description:
                  'Looks like you haven\'t added any essentials to your cart yet. Browse our custom products!',
              buttonText: 'Browse Products',
              onButtonPressed: () => context.pop(),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Cart Item List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return _buildCartItemCard(context, item, shopNotifier);
                      },
                    ),
                  ),

                  // Pricing and Promo details sheet
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      16.h,
                      20.w,
                      MediaQuery.of(context).padding.bottom + 16.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Promo code input row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46.h,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: _promoError != null
                                        ? Colors.red.withOpacity(0.4)
                                        : AppColors.primary.withOpacity(0.05),
                                  ),
                                ),
                                child: TextField(
                                  controller: _promoController,
                                  enabled: !_isPromoApplied,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _isPromoApplied
                                        ? 'MAATRIVA20 applied'
                                        : 'Enter Promo Code (MAATRIVA20)',
                                    hintStyle: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.4),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.local_offer_outlined,
                                      color: AppColors.primary.withOpacity(0.5),
                                      size: 18.r,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            ElevatedButton(
                              onPressed: _isPromoApplied ? null : _applyPromo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[200],
                                disabledForegroundColor: Colors.grey[400],
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isPromoApplied ? 'Applied' : 'Apply',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_promoError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h, left: 8.w),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _promoError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),

                        // Subtotal Row
                        _buildPriceRow(
                          'Subtotal',
                          '\$${subtotal.toStringAsFixed(2)}',
                        ),
                        SizedBox(height: 8.h),

                        // Delivery Fee Row
                        _buildPriceRow(
                          'Delivery Fee',
                          deliveryFee == 0.0
                              ? 'FREE'
                              : '\$${deliveryFee.toStringAsFixed(2)}',
                          isGreen: deliveryFee == 0.0,
                        ),
                        SizedBox(height: 8.h),

                        // Promo Discount Row (if any)
                        if (_isPromoApplied) ...[
                          _buildPriceRow(
                            'Discount (20%)',
                            '-\$${discountAmount.toStringAsFixed(2)}',
                            isGreen: true,
                          ),
                          SizedBox(height: 8.h),
                        ],

                        const Divider(color: AppColors.divider, thickness: 1.5),
                        SizedBox(height: 10.h),

                        // Total Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Order',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showCheckoutDialog(total),
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
                                  Icons.payment_rounded,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Proceed to Checkout',
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
                ],
              ),
            ),
    );
  }

  Widget _buildPriceRow(String label, String val, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 13.sp,
            color: isGreen ? const Color(0xFF109F6E) : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    ShopNotifier notifier,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.r),
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
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.network(
              item.product.imageUrl,
              width: 70.w,
              height: 70.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12.w),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Category: ${item.product.category}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '\$${item.product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Quantity and Remove actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  notifier.removeFromCart(item.product.id);
                },
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[400],
                    size: 18.r,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Plus/Minus Quantity incrementers
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                padding: EdgeInsets.all(2.r),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => notifier.updateQuantity(item.product.id, -1),
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3EDFA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => notifier.updateQuantity(item.product.id, 1),
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
