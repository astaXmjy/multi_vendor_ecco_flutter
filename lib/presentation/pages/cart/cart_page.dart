// lib/presentation/pages/cart/cart_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/cart_item_card.dart';
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
    // Fetch cart items when page loads
    Future.microtask(() =>
        Provider.of<CartProvider>(context, listen: false).fetchCartItems());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Cart',
        showBackButton: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Show loading indicator
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF7A2E),
              ),
            );
          }

          // Show error message
          if (cartProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cart',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(cartProvider.error!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => cartProvider.fetchCartItems(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A2E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          // Show empty cart
          if (cartProvider.items.isEmpty) {
            return const EmptyCart();
          }

          // Show cart items
          return Column(
            children: [
              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (ctx, index) {
                    final item = cartProvider.items[index];
                    return CartItemCard(
                      item: item,
                      onIncrement: () =>
                          cartProvider.incrementQuantity(item.id),
                      onDecrement: () =>
                          cartProvider.decrementQuantity(item.id),
                      onRemove: () => cartProvider.removeItem(item.id),
                    );
                  },
                ),
              ),

              // Cart summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${cartProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'PROCEED TO CHECKOUT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}
