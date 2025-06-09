import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../config/theme.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/enhanced_cart_item_card.dart';
import 'widgets/cart_summary_card.dart';
import 'widgets/empty_cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CartProvider>(context, listen: false).fetchCartItems());
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'My Cart',
        showBackButton: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearCartDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (cartProvider.error != null) {
            return _buildErrorView(cartProvider.error!);
          }

          if (cartProvider.items.isEmpty) {
            return const EmptyCart();
          }

          return _buildCartContent(context, cartProvider, isTablet);
        },
      ),
    );
  }

  Widget _buildCartContent(
      BuildContext context, CartProvider cartProvider, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet && constraints.maxWidth > 800) {
          // Tablet/Desktop layout with side-by-side content
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cart items (70% width)
              Expanded(
                flex: 7,
                child: _buildCartList(cartProvider),
              ),
              const SizedBox(width: 16),
              // Summary (30% width)
              Expanded(
                flex: 3,
                child: _buildStickyCartSummary(cartProvider),
              ),
            ],
          );
        } else {
          // Mobile layout with bottom summary
          return Column(
            children: [
              Expanded(
                child: _buildCartList(cartProvider),
              ),
              _buildBottomSummary(cartProvider),
            ],
          );
        }
      },
    );
  }

  Widget _buildCartList(CartProvider cartProvider) {
    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: cartProvider.items.length,
      itemBuilder: (context, index) {
        final item = cartProvider.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EnhancedCartItemCard(
            item: item,
            onIncrement: () => cartProvider.incrementQuantity(item.id),
            onDecrement: () => cartProvider.decrementQuantity(item.id),
            onRemove: () =>
                _showRemoveItemDialog(context, item.id, cartProvider),
          ),
        );
      },
    );
  }

  Widget _buildStickyCartSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CartSummaryCard(
            cartProvider: cartProvider,
            onCheckout: () => context.go('/checkout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CartSummaryCard(
            cartProvider: cartProvider,
            onCheckout: () => context.go('/checkout'),
            isCompact: true,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading cart',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false)
                  .fetchCartItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(
      BuildContext context, int itemId, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remove Item'),
          content: const Text(
              'Are you sure you want to remove this item from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.removeItem(itemId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear Cart'),
          content: const Text(
              'Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<CartProvider>(context, listen: false).clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
