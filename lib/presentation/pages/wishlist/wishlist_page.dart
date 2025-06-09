// lib/presentation/pages/wishlist/wishlist_page.dart
import 'package:anu_app/presentation/pages/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/wishlist_item_model.dart';
import 'widgets/wishlist_item_card.dart';
import 'widgets/empty_wishlist.dart';
import 'widgets/wishlist_loading.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    // Fetch wishlist items when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().fetchWishlistItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'My Wishlist',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            if (wishlistProvider.wishlistItems.isNotEmpty) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'clear_all') {
                    await _showClearWishlistDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        if (wishlistProvider.isLoading) {
          return const WishlistLoading();
        }

        if (wishlistProvider.errorMessage != null) {
          return _buildErrorState(context, wishlistProvider.errorMessage!);
        }

        if (wishlistProvider.isEmpty) {
          return const EmptyWishlist();
        }

        return _buildWishlistContent(context, wishlistProvider);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: AppTheme.getTitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<WishlistProvider>().fetchWishlistItems();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(
      BuildContext context, WishlistProvider provider) {
    final screenSize = AppTheme.getScreenSize(context);
    final crossAxisCount = screenSize == ScreenSize.mobile ? 1 : 2;

    return RefreshIndicator(
      onRefresh: () => provider.fetchWishlistItems(),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Wishlist header with count
          SliverToBoxAdapter(
            child: Container(
              padding: AppTheme.getResponsivePadding(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.wishlistCount} ${provider.wishlistCount == 1 ? 'Item' : 'Items'}',
                        style: TextStyle(
                          fontSize: AppTheme.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Swipe to remove items',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (provider.wishlistCount > 1)
                    TextButton.icon(
                      onPressed: () => _showMoveAllToCartDialog(context),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Add All to Cart'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Wishlist items grid/list
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.isMobile(context) ? 16 : 24,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = provider.wishlistItems[index];
                  return WishlistItemCard(
                    item: item,
                    onRemove: () => _removeItem(context, item),
                    onAddToCart: () => _addToCart(context, item),
                    onTap: () => _navigateToProduct(context, item),
                  );
                },
                childCount: provider.wishlistItems.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: AppTheme.isMobile(context) ? 0.8 : 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _removeItem(BuildContext context, WishlistItemModel item) async {
    final success = await context.read<WishlistProvider>().removeFromWishlist(
          item.productId,
          variantId: item.variantId,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productInfo.name} removed from wishlist'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              context.read<WishlistProvider>().addToWishlist(
                    item.productId,
                    variantId: item.variantId,
                  );
            },
          ),
        ),
      );
    }
  }

  Future<void> _addToCart(BuildContext context, WishlistItemModel item) async {
    final success =
        await context.read<WishlistProvider>().addWishlistItemToCart(item);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productInfo.name} added to cart'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    }
  }

  void _navigateToProduct(BuildContext context, WishlistItemModel item) {
    context.go('/product/${item.productInfo.slug}');
  }

  Future<void> _showClearWishlistDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Clear Wishlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your wishlist? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<WishlistProvider>().clearWishlist();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wishlist cleared successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showMoveAllToCartDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Add All to Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Would you like to add all wishlist items to your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _addAllToCart(context);
    }
  }

  Future<void> _addAllToCart(BuildContext context) async {
    final provider = context.read<WishlistProvider>();
    final items = provider.wishlistItems;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int totalItems = items.length;

    for (final item in items) {
      final success = await provider.addWishlistItemToCart(item);
      if (success) successCount++;
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (successCount == totalItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All $successCount items added to cart'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount of $totalItems items added to cart'),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
