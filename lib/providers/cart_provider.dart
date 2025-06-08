// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../api/services/cart_service.dart';
import '../core/models/cart_item_model.dart';
import '../core/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => [..._items];
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  // Fetch cart items from API
  Future<void> fetchCartItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _cartService.getCartItems();

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> itemsJson = data['items'];
        
        _items = itemsJson.map((item) => CartItem.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load cart: $e';
      notifyListeners();
    }
  }

  // Add item to cart
  Future<void> addItem(ProductModel product, {
    int quantity = 1,
    String? variantId,
    double? price,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use sale price if available, otherwise use regular price
      final productPrice = price ?? 
          (double.tryParse(product.salePrice) ?? 
           double.tryParse(product.regularPrice) ?? 
           0.0);

      final result = await _cartService.addToCart(
        productId: product.id.toString(),
        variantId: variantId,
        quantity: quantity,
        price: productPrice,
      );

      if (result['success']) {
        await fetchCartItems(); // Refresh cart after adding
      } else {
        _isLoading = false;
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add item: $e';
      notifyListeners();
    }
  }

  // Increment quantity
  Future<void> incrementQuantity(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _items[index];
      final newQuantity = item.quantity + 1;

      try {
        final result = await _cartService.updateCartItemQuantity(
          itemId: itemId,
          quantity: newQuantity,
        );

        if (result['success']) {
          await fetchCartItems(); // Refresh cart after updating
        } else {
          _error = result['message'];
          notifyListeners();
        }
      } catch (e) {
        _error = 'Failed to update quantity: $e';
        notifyListeners();
      }
    }
  }

  // Decrement quantity
  Future<void> decrementQuantity(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _items[index];
      
      if (item.quantity > 1) {
        final newQuantity = item.quantity - 1;

        try {
          final result = await _cartService.updateCartItemQuantity(
            itemId: itemId,
            quantity: newQuantity,
          );

          if (result['success']) {
            await fetchCartItems(); // Refresh cart after updating
          } else {
            _error = result['message'];
            notifyListeners();
          }
        } catch (e) {
          _error = 'Failed to update quantity: $e';
          notifyListeners();
        }
      } else {
        // If quantity is 1, remove the item
        await removeItem(itemId);
      }
    }
  }

  // Remove item from cart
  Future<void> removeItem(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _items[index];

      try {
        final result = await _cartService.removeFromCart(
          productId: item.productId,
          variantId: item.variantId,
        );

        if (result['success']) {
          await fetchCartItems(); // Refresh cart after removing
        } else {
          _error = result['message'];
          notifyListeners();
        }
      } catch (e) {
        _error = 'Failed to remove item: $e';
        notifyListeners();
      }
    }
  }

  // Clear cart error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Add this method to your CartProvider class
  
  // Clear cart
  Future<void> clear() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
  
    try {
      // Here you would implement an API call to clear the cart if needed
      // For now, we'll just clear the local items
      _items = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to clear cart: $e';
      notifyListeners();
    }
  }
}
