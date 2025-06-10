// lib/providers/wishlist_provider.dart - Enhanced with cart_image_service
import 'package:flutter/material.dart';
import '../api/services/wishlist_service.dart';
import '../api/services/cart_service.dart';
import '../api/services/cart_image_service.dart'; // Added image service
import '../core/models/wishlist_item_model.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  final CartImageService _imageService =
      CartImageService(); // Added image service

  List<WishlistItemModel> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _wishlistCount = 0;
  Map<String, String> _itemImages = {}; // Cache for item images

  // Getters
  List<WishlistItemModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get wishlistCount => _wishlistCount;
  bool get isEmpty => _wishlistItems.isEmpty;

  // Get cached image URL for a wishlist item
  String? getItemImageUrl(WishlistItemModel item) {
    final key = '${item.productId}_${item.variantId ?? 'default'}';
    return _itemImages[key];
  }

  // Check if a product is in wishlist
  bool isInWishlist(String productId, {String? variantId}) {
    return _wishlistItems.any(
        (item) => item.productId == productId && item.variantId == variantId);
  }

  // Get wishlist item by product ID
  WishlistItemModel? getWishlistItem(String productId, {String? variantId}) {
    try {
      return _wishlistItems.firstWhere(
          (item) => item.productId == productId && item.variantId == variantId);
    } catch (e) {
      return null;
    }
  }

  // Fetch wishlist items from API
  Future<void> fetchWishlistItems() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _wishlistService.getWishlistItems();

      if (result['success']) {
        _wishlistItems = result['data']['items'] ?? [];
        _wishlistCount = result['data']['count'] ?? 0;

        // Load variant-specific images for each wishlist item
        await _loadWishlistItemImages();

        print('Wishlist fetched successfully: ${_wishlistItems.length} items');
      } else {
        _setError(result['message'] ?? 'Failed to fetch wishlist');
        print('Failed to fetch wishlist: ${result['message']}');
      }
    } catch (e) {
      _setError('An error occurred while fetching wishlist: $e');
      print('Error fetching wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load variant-specific images for wishlist items
  Future<void> _loadWishlistItemImages() async {
    for (final item in _wishlistItems) {
      if (item.productInfo.slug.isNotEmpty) {
        try {
          final imageUrl = await _imageService.getCartItemImageUrl(
            item.productInfo.slug,
            item.variantId,
          );

          if (imageUrl != null) {
            final key = '${item.productId}_${item.variantId ?? 'default'}';
            _itemImages[key] = imageUrl;
          }
        } catch (e) {
          print('Error loading image for wishlist item ${item.id}: $e');
        }
      }
    }
    notifyListeners();
  }

  // Add item to wishlist
  Future<bool> addToWishlist(String productId, {String? variantId}) async {
    try {
      // Check if already in wishlist
      if (isInWishlist(productId, variantId: variantId)) {
        _setError('Item is already in your wishlist');
        return false;
      }

      final result = await _wishlistService.addToWishlist(
        productId: productId,
        variantId: variantId,
      );

      if (result['success']) {
        // Refresh the wishlist after adding
        await fetchWishlistItems();
        _clearError();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to add item to wishlist');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while adding to wishlist: $e');
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove item from wishlist
  Future<bool> removeFromWishlist(String productId, {String? variantId}) async {
    try {
      final result = await _wishlistService.removeFromWishlist(
        productId: productId,
        variantId: variantId,
      );

      if (result['success']) {
        // Remove item from local list immediately for better UX
        _wishlistItems.removeWhere((item) =>
            item.productId == productId && item.variantId == variantId);
        _wishlistCount = _wishlistItems.length;

        // Remove cached image
        final key = '${productId}_${variantId ?? 'default'}';
        _itemImages.remove(key);

        notifyListeners();

        _clearError();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to remove item from wishlist');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while removing from wishlist: $e');
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // Toggle wishlist status
  Future<bool> toggleWishlist(String productId, {String? variantId}) async {
    if (isInWishlist(productId, variantId: variantId)) {
      return await removeFromWishlist(productId, variantId: variantId);
    } else {
      return await addToWishlist(productId, variantId: variantId);
    }
  }

  // Clear entire wishlist
  Future<bool> clearWishlist() async {
    try {
      // Show confirmation dialog would be handled in UI
      final result = await _wishlistService.clearWishlist();

      if (result['success']) {
        _wishlistItems.clear();
        _wishlistCount = 0;
        _itemImages.clear(); // Clear image cache
        notifyListeners();
        _clearError();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to clear wishlist');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while clearing wishlist: $e');
      print('Error clearing wishlist: $e');
      return false;
    }
  }

  // Add wishlist item to cart
  Future<bool> addWishlistItemToCart(WishlistItemModel item) async {
    try {
      final result = await _cartService.addToCart(
        productId: item.productId,
        variantId: item.variantId,
        quantity: 1,
        price: item.productInfo.displayPrice,
      );

      if (result['success']) {
        _clearError();
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to add item to cart');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while adding to cart: $e');
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Move wishlist item to cart (add to cart and remove from wishlist)
  Future<bool> moveToCart(WishlistItemModel item) async {
    try {
      // First add to cart
      final addToCartSuccess = await addWishlistItemToCart(item);

      if (addToCartSuccess) {
        // Then remove from wishlist
        final removeFromWishlistSuccess = await removeFromWishlist(
          item.productId,
          variantId: item.variantId,
        );

        return removeFromWishlistSuccess;
      }

      return false;
    } catch (e) {
      _setError('An error occurred while moving item to cart: $e');
      print('Error moving to cart: $e');
      return false;
    }
  }

  // Update wishlist item image
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
      print('Error updating wishlist item image: $e');
    }
  }

  // Refresh wishlist items (pull to refresh)
  Future<void> refreshWishlist() async {
    await fetchWishlistItems();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _wishlistItems.clear();
    _wishlistCount = 0;
    _isLoading = false;
    _errorMessage = null;
    _itemImages.clear(); // Clear image cache
    notifyListeners();
  }

  // Initialize wishlist (call this when user logs in)
  Future<void> initialize() async {
    await fetchWishlistItems();
  }
}
