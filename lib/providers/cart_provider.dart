// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../core/models/cart_item_model.dart';
import '../core/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Add item to cart
  void addItem(ProductModel product,
      {int quantity = 1,
      String? variantId,
      Map<String, String>? selectedOptions}) {
    // Check if the product already exists in cart
    final existingItemIndex = _items.indexWhere((item) =>
        item.productId == product.id.toString() &&
        (variantId == null || item.variantId == variantId));

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + quantity,
      );
    } else {
      // Add new item
      _items.add(
        CartItem(
          id: DateTime.now().toString(),
          productId: product.id.toString(),
          name: product.name,
          imageUrl: product.primaryImageUrl,
          price: double.tryParse(product.salePrice) ?? 0.0,
          quantity: quantity,
          variantId: variantId,
          selectedOptions: selectedOptions,
        ),
      );
    }

    notifyListeners();
  }

  // Increment quantity
  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  // Decrement quantity
  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
