import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../data/mock_products.dart';

class ShopState {
  final List<Product> products;
  final List<CategoryItem> categories;
  final List<CartItem> cart;
  final List<String> wishlist; // List of Product IDs
  final String searchQuery;
  final String selectedCategory;
  final ProductFilter filter;

  const ShopState({
    required this.products,
    required this.categories,
    required this.cart,
    required this.wishlist,
    required this.searchQuery,
    required this.selectedCategory,
    required this.filter,
  });

  ShopState copyWith({
    List<Product>? products,
    List<CategoryItem>? categories,
    List<CartItem>? cart,
    List<String>? wishlist,
    String? searchQuery,
    String? selectedCategory,
    ProductFilter? filter,
  }) {
    return ShopState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      cart: cart ?? this.cart,
      wishlist: wishlist ?? this.wishlist,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      filter: filter ?? this.filter,
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier()
    : super(
        ShopState(
          products: initialMockProducts,
          categories: initialCategories,
          cart: [
            CartItem(
              product: initialMockProducts[1],
              quantity: 2,
            ), // Pre-load Soft Touch Pacifier with qty 2 as in screenshot badge
          ],
          wishlist: [
            initialMockProducts[1].id,
          ], // Pacifier preloaded in wishlist (red heart)
          searchQuery: '',
          selectedCategory: 'All',
          filter: const ProductFilter(),
        ),
      );

  // --- Search & Filtering Actions ---

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String categoryName) {
    state = state.copyWith(selectedCategory: categoryName);
  }

  void applyFilter(ProductFilter newFilter) {
    state = state.copyWith(filter: newFilter);
  }

  void resetFilters() {
    state = state.copyWith(filter: const ProductFilter());
  }

  // --- Cart Actions ---

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = state.cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    final updatedCart = List<CartItem>.from(state.cart);

    if (existingIndex >= 0) {
      final currentItem = state.cart[existingIndex];
      updatedCart[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + quantity,
      );
    } else {
      updatedCart.add(CartItem(product: product, quantity: quantity));
    }
    state = state.copyWith(cart: updatedCart);
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      cart: state.cart.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int delta) {
    final updatedCart = state.cart.map((item) {
      if (item.product.id == productId) {
        final newQty = item.quantity + delta;
        return item.copyWith(quantity: newQty > 0 ? newQty : 1);
      }
      return item;
    }).toList();
    state = state.copyWith(cart: updatedCart);
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }

  // --- Wishlist Actions ---

  void toggleWishlist(String productId) {
    final list = List<String>.from(state.wishlist);
    if (list.contains(productId)) {
      list.remove(productId);
    } else {
      list.add(productId);
    }
    state = state.copyWith(wishlist: list);
  }

  bool isInWishlist(String productId) {
    return state.wishlist.contains(productId);
  }

  // --- Filtered Products Getter ---

  List<Product> getFilteredProducts() {
    return state.products.where((product) {
      // 1. Category check
      if (state.selectedCategory != 'All' &&
          product.category.toLowerCase() !=
              state.selectedCategory.toLowerCase()) {
        return false;
      }
      if (state.filter.selectedCategory != 'All' &&
          product.category.toLowerCase() !=
              state.filter.selectedCategory.toLowerCase()) {
        return false;
      }

      // 2. Search check
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final nameMatch = product.name.toLowerCase().contains(query);
        final descMatch = product.description.toLowerCase().contains(query);
        final catMatch = product.category.toLowerCase().contains(query);
        if (!nameMatch && !descMatch && !catMatch) {
          return false;
        }
      }

      // 3. Price check
      if (product.price < state.filter.minPrice ||
          product.price > state.filter.maxPrice) {
        return false;
      }

      // 4. Rating check
      if (product.rating < state.filter.selectedRating) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) {
      switch (state.filter.sortBy) {
        case 'Newest':
          return b.isNewArrival ? 1 : -1;
        case 'Lowest Price':
          return a.price.compareTo(b.price);
        case 'Highest Price':
          return b.price.compareTo(a.price);
        case 'Highest Rated':
          return b.rating.compareTo(a.rating);
        case 'Popular':
        default:
          return b.reviewsCount.compareTo(a.reviewsCount);
      }
    });
  }

  // Helpers

  int get cartCount {
    return state.cart.fold(0, (sum, item) => sum + item.quantity);
  }

  double get cartTotal {
    return state.cart.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }
}

// Riverpod Provider
final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier();
});
