// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../api/services/cart_service.dart';
import '../api/services/cart_image_service.dart';
import '../core/models/cart_item_model.dart';
import '../core/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final CartImageService _imageService = CartImageService();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _itemImages = {}; // Cache for item images

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

  // Get cached image URL for a cart item
  String? getItemImageUrl(CartItem item) {
    final key = '${item.productId}_${item.variantId ?? 'default'}';
    return _itemImages[key];
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

        // Load variant-specific images for each cart item
        await _loadCartItemImages();

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

  // Load variant-specific images for cart items
  Future<void> _loadCartItemImages() async {
    for (final item in _items) {
      if (item.productInfo?.slug != null) {
        try {
          final imageUrl = await _imageService.getCartItemImageUrl(
            item.productInfo!.slug,
            item.variantId,
          );

          if (imageUrl != null) {
            final key = '${item.productId}_${item.variantId ?? 'default'}';
            _itemImages[key] = imageUrl;
          }
        } catch (e) {
          print('Error loading image for item ${item.id}: $e');
        }
      }
    }
    notifyListeners();
  }

  // Add item to cart
  Future<void> addItem(
    ProductModel product, {
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
        // Load variant-specific image for the new item
        if (variantId != null) {
          try {
            final imageUrl = await _imageService.getCartItemImageUrl(
              product.slug,
              variantId,
            );
            if (imageUrl != null) {
              final key = '${product.id}_$variantId';
              _itemImages[key] = imageUrl;
            }
          } catch (e) {
            print('Error loading variant image: $e');
          }
        }

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
          // Remove cached image
          final key = '${item.productId}_${item.variantId ?? 'default'}';
          _itemImages.remove(key);

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

  // Clear cart
  Future<void> clear() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Clear all items one by one (if no bulk clear API is available)
      for (final item in _items) {
        await _cartService.removeFromCart(
          productId: item.productId,
          variantId: item.variantId,
        );
      }

      // Clear local data
      _items = [];
      _itemImages.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to clear cart: $e';
      notifyListeners();
    }
  }

  // Refresh cart items (pull to refresh)
  Future<void> refreshCart() async {
    await fetchCartItems();
  }

  // Check if specific product variant is in cart
  bool isProductInCart(String productId, {String? variantId}) {
    return _items.any(
        (item) => item.productId == productId && item.variantId == variantId);
  }

  // Get quantity of specific product variant in cart
  int getProductQuantity(String productId, {String? variantId}) {
    final item = _items.firstWhere(
      (item) => item.productId == productId && item.variantId == variantId,
      orElse: () => CartItem(
        id: 0,
        productId: '',
        quantity: 0,
        price: 0,
        totalPrice: 0,
        addedAt: '',
        updatedAt: '',
      ),
    );
    return item.quantity;
  }

  // Update cart item with variant-specific image
  Future<void> updateItemImage(
      String productId, String? variantId, String productSlug) async {
    try {
      final imageUrl = await _imageService.getCartItemImageUrl(
        productSlug,
        variantId,
      );

      if (imageUrl != null) {
        final key = '${productId}_${variantId ?? 'default'}';
        _itemImages[key] = imageUrl;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating item image: $e');
    }
  }
}
