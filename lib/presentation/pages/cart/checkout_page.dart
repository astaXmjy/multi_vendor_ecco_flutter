// lib/presentation/pages/cart/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../shared/custom_app_bar.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Checkout',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Items summary
            Expanded(
              child: ListView.builder(
                itemCount: cartProvider.items.length,
                itemBuilder: (context, index) {
                  final item = cartProvider.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '₹${item.price.toStringAsFixed(2)} × ${item.quantity}'),
                    trailing: Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}'),
                  );
                },
              ),
            ),

            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('₹${cartProvider.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Shipping'),
                      Text('₹50.00'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(cartProvider.totalAmount + 50.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Place order button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Process order
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order placed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Clear cart
                  cartProvider.clear();

                  // Navigate to home
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
