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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image and badges - fixed height with aspect ratio
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
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

                  // Wishlist button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: onWishlistTap,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          product.isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isWishlisted
                              ? const Color(0xFFFF4947)
                              : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info - use remaining height with flexible layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13, // Smaller for more space
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1, // Limit to 1 line to save space
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Seller name if available (optional)
                        if (product.sellerInfo != null &&
                            constraints.maxHeight > 60)
                          Text(
                            'by ${product.sellerInfo!.userName}',
                            style: TextStyle(
                              fontSize: 9, // Even smaller
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const Spacer(), // Push remaining content to bottom

                        // Price row
                        Row(
                          children: [
                            Text(
                              product.formattedSalePrice,
                              style: const TextStyle(
                                fontSize: 13, // Smaller
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7A2E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (product.discountPercentage.isNotEmpty)
                              Expanded(
                                child: Text(
                                  product.formattedRegularPrice,
                                  style: TextStyle(
                                    fontSize: 10, // Smaller
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 2), // Minimal spacing

                        // Add to Cart button
                        SizedBox(
                          width: double.infinity,
                          height: 22, // Fixed small height
                          child: TextButton.icon(
                            onPressed: () {
                              final cartProvider = Provider.of<CartProvider>(
                                  context,
                                  listen: false);
                              cartProvider.addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Added to cart'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'VIEW',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      context.push('/cart');
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              size: 12, // Very small icon
                            ),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(fontSize: 10), // Very small text
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF7A2E),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
