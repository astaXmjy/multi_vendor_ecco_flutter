// lib/presentation/pages/wishlist/widgets/wishlist_item_card.dart - Enhanced with image service
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/wishlist_item_model.dart';
import '../../../../providers/wishlist_provider.dart';
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
    final isTablet = AppTheme.isTablet(context);

    return Dismissible(
      key: Key('wishlist_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: _buildDismissBackground(context),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal:
                AppTheme.getResponsiveHorizontalPadding(context).horizontal / 2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius:
                BorderRadius.circular(AppTheme.getCardRadius(context)),
            boxShadow: AppTheme.getCardShadow(
                elevation: AppTheme.getCardElevation(context)),
          ),
          child: isTablet
              ? _buildTabletLayout(context)
              : _buildMobileLayout(context),
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
            padding: AppTheme.getResponsiveCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductName(context),
                const SizedBox(height: 4),
                _buildPriceSection(context),
                const SizedBox(height: 8),
                _buildStockStatus(context),
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
      padding: AppTheme.getResponsiveCardPadding(context),
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
                    _buildProductName(context),
                    const SizedBox(height: 8),
                    _buildPriceSection(context),
                    const SizedBox(height: 8),
                    _buildStockStatus(context),
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
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        // Get the variant-specific image URL from the provider
        final variantImageUrl = wishlistProvider.getItemImageUrl(item);
        // Use variant image if available, otherwise fallback to product info image
        final imageUrl = variantImageUrl ?? item.productInfo.image ?? '';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppTheme.getCardRadius(context)),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppTheme.getCardRadius(context)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImageSkeleton();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        );
      },
    );
  }

  Widget _buildImageSkeleton() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
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

  Widget _buildProductName(BuildContext context) {
    return Text(
      item.productInfo.name,
      style: TextStyle(
        fontSize: AppTheme.getTitleFontSize(context),
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Row(
      children: [
        Text(
          item.productInfo.formattedPrice,
          style: TextStyle(
            fontSize: AppTheme.getBodyFontSize(context) + 2,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (item.productInfo.hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            item.productInfo.formattedRegularPrice,
            style: TextStyle(
              fontSize: AppTheme.getCaptionFontSize(context),
              color: AppTheme.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.productInfo.discountPercentage.toInt()}% OFF',
              style: TextStyle(
                fontSize: AppTheme.getCaptionFontSize(context) - 1,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatus(BuildContext context) {
    final inStock = item.productInfo.isAvailable;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: inStock ? AppTheme.successColor : AppTheme.errorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? 'In Stock' : 'Out of Stock',
          style: TextStyle(
            fontSize: AppTheme.getCaptionFontSize(context),
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
              size: AppTheme.getSmallIconSize(context),
            ),
            label: Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: isMobile ? 12 : AppTheme.getBodyFontSize(context),
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
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 6 : 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.getButtonRadius(context)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline,
            color: AppTheme.errorColor,
            size: AppTheme.getSmallIconSize(context),
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.errorColor.withOpacity(0.1),
            padding: EdgeInsets.all(isMobile ? 8 : 12),
          ),
          tooltip: 'Remove from wishlist',
        ),
      ],
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: AppTheme.getIconSize(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTheme.getCaptionFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
