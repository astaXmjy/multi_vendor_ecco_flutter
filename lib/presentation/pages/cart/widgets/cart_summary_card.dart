// lib/presentation/pages/cart/widgets/cart_summary_card.dart
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
    return Card(
      elevation: AppTheme.getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
      ),
      child: Padding(
        padding: AppTheme.getResponsiveCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isCompact) ...[
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: AppTheme.getTitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subtotal
            _buildSummaryRow(
              context,
              'Subtotal (${cartProvider.itemCount} items)',
              '₹${cartProvider.subtotal.toStringAsFixed(0)}',
              isSubtitle: true,
            ),

            if (!isCompact) const SizedBox(height: 8),

            // Shipping
            _buildSummaryRow(
              context,
              'Shipping',
              cartProvider.shippingCost > 0
                  ? '₹${cartProvider.shippingCost.toStringAsFixed(0)}'
                  : 'FREE',
              isSubtitle: true,
              valueColor:
                  cartProvider.shippingCost > 0 ? null : AppTheme.successColor,
            ),

            if (!isCompact && cartProvider.taxAmount > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                'Tax',
                '₹${cartProvider.taxAmount.toStringAsFixed(0)}',
                isSubtitle: true,
              ),
            ],

            if (!isCompact && cartProvider.totalSavings > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                'You Save',
                '-₹${cartProvider.totalSavings.toStringAsFixed(0)}',
                isSubtitle: true,
                valueColor: AppTheme.successColor,
              ),
            ],

            const SizedBox(height: 12),

            const Divider(thickness: 1),

            const SizedBox(height: 12),

            // Total
            _buildSummaryRow(
              context,
              'Total',
              '₹${cartProvider.finalTotal.toStringAsFixed(0)}',
              isBold: true,
            ),

            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated delivery: ${cartProvider.estimatedDeliveryDate}',
                style: TextStyle(
                  fontSize: AppTheme.getCaptionFontSize(context),
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              height: AppTheme.getButtonHeight(context),
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppTheme.getButtonRadius(context)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: AppTheme.getSmallIconSize(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: AppTheme.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!isCompact && cartProvider.shippingCost > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: AppTheme.getSmallIconSize(context),
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add ₹${(500 - cartProvider.subtotal).toStringAsFixed(0)} more for FREE shipping',
                        style: TextStyle(
                          fontSize: AppTheme.getCaptionFontSize(context),
                          color: AppTheme.successColor,
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
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool isSubtitle = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubtitle
                ? AppTheme.getBodyFontSize(context)
                : AppTheme.getTitleFontSize(context),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isSubtitle ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSubtitle
                ? AppTheme.getBodyFontSize(context)
                : AppTheme.getTitleFontSize(context),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ??
                (isBold ? AppTheme.primaryColor : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
