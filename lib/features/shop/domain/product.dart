import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final double price;
  final double rating;
  final int reviewsCount;
  final bool isNewArrival;
  final bool isFeatured;
  final List<String> features;
  final Map<String, String> specifications;
  final List<ProductReview> reviews;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviewsCount,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.features = const [],
    this.specifications = const {},
    this.reviews = const [],
  });
}

class ProductReview {
  final String reviewerName;
  final double rating;
  final String comment;
  final String date;

  const ProductReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color activeColor;
  final Color inactiveColor;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.activeColor,
    required this.inactiveColor,
  });
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ProductFilter {
  final String selectedCategory;
  final double minPrice;
  final double maxPrice;
  final double selectedRating;
  final String selectedBrand;
  final String
  sortBy; // Popular, Newest, Lowest Price, Highest Price, Highest Rated

  const ProductFilter({
    this.selectedCategory = 'All',
    this.minPrice = 0.0,
    this.maxPrice = 200.0,
    this.selectedRating = 0.0,
    this.selectedBrand = 'All',
    this.sortBy = 'Popular',
  });

  ProductFilter copyWith({
    String? selectedCategory,
    double? minPrice,
    double? maxPrice,
    double? selectedRating,
    String? selectedBrand,
    String? sortBy,
  }) {
    return ProductFilter(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedRating: selectedRating ?? this.selectedRating,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
