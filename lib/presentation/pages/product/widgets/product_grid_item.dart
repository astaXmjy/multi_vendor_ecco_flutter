// lib/presentation/pages/product/widgets/product_grid_item.dart
import 'package:anu_app/main.dart';
import 'package:anu_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/product_model.dart';

class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;

  const ProductGridItem({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onWishlistTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section - using Flexible instead of AspectRatio
            Flexible(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[100],
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, error, _) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: isSmallScreen ? 30 : 40,
                                ),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: const Color(0xFFFF7A2E),
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: isSmallScreen ? 30 : 40,
                              ),
                            ),
                    ),
                  ),

                  // Discount badge
                  if (product.discountPercentage.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4947),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercentage}% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onWishlistTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isWishlisted
                              ? const Color(0xFFFF4947)
                              : Colors.grey[600],
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info section - using Flexible for better space management
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name - fixed height to prevent overflow
                    SizedBox(
                      height: isSmallScreen ? 28 : 32,
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Seller name (optional, only on larger screens)
                    if (!isSmallScreen && product.sellerInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'by ${product.sellerInfo!.userName}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const Spacer(),

                    // Price section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current price
                        Text(
                          product.formattedSalePrice,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF7A2E),
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

// Enhanced navigation function for product details
extension ProductNavigation on ProductGridItem {
  void navigateToProductDetails(BuildContext context) {
    context.push('/product/${product.slug}');
  }
}
