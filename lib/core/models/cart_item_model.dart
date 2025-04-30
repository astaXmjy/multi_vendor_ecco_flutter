// lib/core/models/cart_item_model.dart
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? variantId;
  final Map<String, String>? selectedOptions;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.variantId,
    this.selectedOptions,
  });

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? variantId,
    Map<String, String>? selectedOptions,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      variantId: variantId ?? this.variantId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}
