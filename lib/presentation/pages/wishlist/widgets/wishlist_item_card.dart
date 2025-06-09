// lib/presentation/pages/wishlist/widgets/wishlist_item_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/wishlist_item_model.dart';
import '../../../../config/theme.dart';

class WishlistItemCard extends StatelessWidget {
  final WishlistItemModel item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const WishlistItemCard({
    Key? key,
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);

    return Dismissible(
      key: Key('wishlist_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: _buildDismissBackground(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isMobile
              ? _buildMobileLayout(context)
              : _buildTabletLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Expanded(
          flex: 3,
          child: _buildProductImage(context),
        ),

        // Product Details
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductName(),
                const SizedBox(height: 4),
                _buildPriceSection(),
                const SizedBox(height: 8),
                _buildStockStatus(),
                const Spacer(),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Image
          SizedBox(
            width: 120,
            height: 120,
            child: _buildProductImage(context),
          ),

          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductName(),
                    const SizedBox(height: 8),
                    _buildPriceSection(),
                    const SizedBox(height: 8),
                    _buildStockStatus(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.productInfo.image != null
            ? CachedNetworkImage(
                imageUrl: item.productInfo.image!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      item.productInfo.name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceSection() {
    return Row(
      children: [
        Text(
          item.productInfo.formattedPrice,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (item.productInfo.hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            item.productInfo.formattedRegularPrice,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatus() {
    final inStock = item.productInfo.isAvailable;

    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle : Icons.error,
          size: 14,
          color: inStock ? AppTheme.successColor : AppTheme.errorColor,
        ),
        const SizedBox(width: 4),
        Text(
          inStock ? 'In Stock' : 'Out of Stock',
          style: TextStyle(
            fontSize: 12,
            color: inStock ? AppTheme.successColor : AppTheme.errorColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isMobile = AppTheme.isMobile(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: item.productInfo.isAvailable ? onAddToCart : null,
            icon: Icon(
              Icons.shopping_cart_outlined,
              size: isMobile ? 16 : 18,
            ),
            label: Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(
                color: item.productInfo.isAvailable
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 8,
                horizontal: isMobile ? 8 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Remove button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.delete_outline,
                size: isMobile ? 16 : 18,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
