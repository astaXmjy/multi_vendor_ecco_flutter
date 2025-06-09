// lib/presentation/pages/home/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../../providers/wishlist_provider.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Function(ProductModel)? onWishlistTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image, discount badge, and wishlist button
            Stack(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: product.primaryImageUrl.isNotEmpty
                        ? Image.network(
                            product.primaryImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, _) => Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFFFF7A2E),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                  ),
                ),

                // Discount badge
                if (product.discountPercentage.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4947),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.discountPercentage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Wishlist button with API integration
                Positioned(
                  top: 8,
                  left: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final productId = product.id.toString();
                      final isWishlisted =
                          wishlistProvider.isInWishlist(productId);
                      final isLoading = wishlistProvider.isLoading;

                      return InkWell(
                        onTap: isLoading
                            ? null
                            : () async {
                                if (onWishlistTap != null) {
                                  onWishlistTap!(product);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isWishlisted
                                          ? const Color(0xFFFF4947)
                                          : Colors.grey,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isWishlisted
                                      ? const Color(0xFFFF4947)
                                      : Colors.grey,
                                  size: 20,
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Price section
                    Row(
                      children: [
                        Text(
                          product.formattedSalePrice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A2E),
                          ),
                        ),
                        if (product.discountPercentage.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            product.formattedRegularPrice,
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Stock status
                    Row(
                      children: [
                        Icon(
                          product.stockQuantity > 0
                              ? Icons.check_circle
                              : Icons.error,
                          size: 12,
                          color: product.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.stockQuantity > 0
                                ? 'In Stock'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: product.stockQuantity > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
