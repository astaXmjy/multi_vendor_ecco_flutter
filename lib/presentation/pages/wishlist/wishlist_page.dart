// lib/presentation/pages/wishlist/wishlist_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/wishlist_item_model.dart';
import '../shared/custom_bottom_nav.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/enhanced_wishlist_item_card.dart';
import 'widgets/empty_wishlist.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlist();
    });
  }

  Future<void> _loadWishlist() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    await wishlistProvider.fetchWishlistItems();
  }

  Future<void> _refreshWishlist() async {
    await _loadWishlist();
  }

  void _showRemoveConfirmation(BuildContext context, WishlistItemModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Wishlist'),
          content: Text(
              'Are you sure you want to remove "${item.productInfo.name}" from your wishlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromWishlist(item);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFromWishlist(WishlistItemModel item) async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    final success = await wishlistProvider.removeFromWishlist(
      item.productId,
      variantId: item.variantId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Removed from wishlist'
              : 'Failed to remove from wishlist'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToCart(WishlistItemModel item) async {
    if (!item.productInfo.isAvailable || !item.productInfo.hasValidPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is not available for purchase'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    final success = await wishlistProvider.addWishlistItemToCart(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(seconds: 2),
          action: success
              ? SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/cart'),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _moveToCart(WishlistItemModel item) async {
    if (!item.productInfo.isAvailable || !item.productInfo.hasValidPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is not available for purchase'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    final success = await wishlistProvider.moveToCart(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Moved to cart' : 'Failed to move to cart'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(seconds: 2),
          action: success
              ? SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/cart'),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppTheme.isTablet(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'My Wishlist',
        showBackButton: true,
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              if (wishlistProvider.isEmpty || wishlistProvider.isLoading) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'clear_all':
                      _showClearAllConfirmation(context);
                      break;
                    case 'move_all_to_cart':
                      _moveAllToCart();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'move_all_to_cart',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 20),
                        SizedBox(width: 8),
                        Text('Move All to Cart'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all,
                            size: 20, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Clear All',
                            style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          if (wishlistProvider.isLoading) {
            return _buildLoadingState();
          }

          if (wishlistProvider.errorMessage != null) {
            return _buildErrorState(wishlistProvider.errorMessage!);
          }

          if (wishlistProvider.isEmpty) {
            return const EmptyWishlist();
          }

          return _buildWishlistContent(context, wishlistProvider, isTablet);
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: AppTheme.getHeadlineFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                onPressed: _refreshWishlist,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(
      BuildContext context, WishlistProvider wishlistProvider, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _refreshWishlist,
      color: AppTheme.primaryColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isTablet && constraints.maxWidth > 800) {
            // Tablet/Desktop layout with grid
            return _buildGridLayout(wishlistProvider);
          } else {
            // Mobile layout with list
            return _buildListLayout(wishlistProvider);
          }
        },
      ),
    );
  }

  Widget _buildListLayout(WishlistProvider wishlistProvider) {
    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: wishlistProvider.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = wishlistProvider.wishlistItems[index];
        return EnhancedWishlistItemCard(
          item: item,
          onRemove: () => _showRemoveConfirmation(context, item),
          onAddToCart: () => _addToCart(item),
        );
      },
    );
  }

  Widget _buildGridLayout(WishlistProvider wishlistProvider) {
    return GridView.builder(
      padding: AppTheme.getResponsivePadding(context),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: wishlistProvider.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = wishlistProvider.wishlistItems[index];
        return EnhancedWishlistItemCard(
          item: item,
          onRemove: () => _showRemoveConfirmation(context, item),
          onAddToCart: () => _addToCart(item),
        );
      },
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Wishlist'),
          content: const Text(
              'Are you sure you want to remove all items from your wishlist? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllItems();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllItems() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    final success = await wishlistProvider.clearWishlist();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Wishlist cleared' : 'Failed to clear wishlist'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _moveAllToCart() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final availableItems = wishlistProvider.wishlistItems
        .where((item) =>
            item.productInfo.isAvailable && item.productInfo.hasValidPrice)
        .toList();

    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available items to move to cart'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    for (final item in availableItems) {
      final success = await wishlistProvider.moveToCart(item);
      if (success) successCount++;
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Moved $successCount of ${availableItems.length} items to cart'),
          backgroundColor:
              successCount > 0 ? AppTheme.successColor : AppTheme.errorColor,
          action: successCount > 0
              ? SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/cart'),
                )
              : null,
        ),
      );
    }
  }
}
