// lib/core/models/product_model.dart
class ProductModel {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String discount;
  final String description;
  final bool isWishlisted;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.discount,
    required this.description,
    this.isWishlisted = false,
  });

  // Create a copy of the product with modified properties
  ProductModel copyWith({
    String? id,
    String? name,
    String? price,
    String? imageUrl,
    String? discount,
    String? description,
    bool? isWishlisted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  // Convert from JSON - useful when fetching from API
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      imageUrl: json['image_url'] ?? '',
      discount: json['discount'] ?? '',
      description: json['description'] ?? '',
      isWishlisted: json['is_wishlisted'] ?? false,
    );
  }

  // Convert to JSON - useful when sending to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'discount': discount,
      'description': description,
      'is_wishlisted': isWishlisted,
    };
  }
}
