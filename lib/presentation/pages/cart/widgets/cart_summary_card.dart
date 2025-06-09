import 'package:flutter/material.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../config/theme.dart';

class CartSummaryCard extends StatelessWidget {
  final CartProvider cartProvider;
  final VoidCallback onCheckout;
  final bool isCompact;

  const CartSummaryCard({
    Key? key,
    required this.cartProvider,
    required this.onCheckout,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shippingFee = 50.0;
    final subtotal = cartProvider.totalAmount;
    final total = subtotal + shippingFee;

    return Card(
      elevation: isCompact ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isCompact) ...[
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            _buildSummaryRow('Subtotal', subtotal, isSubtotal: true),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping', shippingFee),
            const SizedBox(height: 8),
            if (subtotal > 500) ...[
              _buildSummaryRow('Discount', -shippingFee, isDiscount: true),
              const SizedBox(height: 8),
            ],
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Total',
              subtotal > 500 ? subtotal : total,
              isTotal: true,
            ),
            SizedBox(height: isCompact ? 12 : 20),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (subtotal <= 500 && !isCompact) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add ₹${(500 - subtotal).toStringAsFixed(0)} more for free shipping!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isSubtotal = false,
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount ? Colors.green.shade700 : null,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? AppTheme.primaryColor
                : isDiscount
                    ? Colors.green.shade700
                    : null,
          ),
        ),
      ],
    );
  }
}
