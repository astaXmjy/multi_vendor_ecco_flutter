// lib/core/models/wishlist_item_model.dart
class WishlistItemModel {
  final int id;
  final String productId;
  final String? variantId;
  final ProductInfo productInfo;
  final String addedAt;

  WishlistItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productInfo,
    required this.addedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'],
      productInfo: ProductInfo.fromJson(json['product_info'] ?? {}),
      addedAt: json['added_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'product_info': productInfo.toJson(),
      'added_at': addedAt,
    };
  }

  // Create an empty wishlist item for fallback
  factory WishlistItemModel.empty() {
    return WishlistItemModel(
      id: 0,
      productId: '',
      variantId: null,
      productInfo: ProductInfo.empty(),
      addedAt: '',
    );
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String slug;
  final String? image;
  final double regularPrice;
  final double salePrice;
  final bool isAvailable;

  ProductInfo({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    required this.regularPrice,
    required this.salePrice,
    required this.isAvailable,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'],
      regularPrice: (json['regular_price'] ?? 0).toDouble(),
      salePrice: (json['sale_price'] ?? 0).toDouble(),
      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'is_available': isAvailable,
    };
  }

  // Helper methods
  double get displayPrice => salePrice > 0 ? salePrice : regularPrice;

  bool get hasDiscount => salePrice > 0 && salePrice < regularPrice;

  double get discountPercentage =>
      hasDiscount ? ((regularPrice - salePrice) / regularPrice * 100) : 0;

  String get formattedPrice => '₹${displayPrice.toStringAsFixed(0)}';

  String get formattedRegularPrice => '₹${regularPrice.toStringAsFixed(0)}';

  // Create an empty product info for fallback
  factory ProductInfo.empty() {
    return ProductInfo(
      id: '',
      name: 'Unknown Product',
      slug: '',
      image: null,
      regularPrice: 0.0,
      salePrice: 0.0,
      isAvailable: false,
    );
  }
}
