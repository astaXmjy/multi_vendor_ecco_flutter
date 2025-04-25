// lib/presentation/pages/product/widgets/product_details_content.dart
import 'package:anu_app/core/models/breadcrumb_model.dart';
import 'package:anu_app/presentation/pages/product/widgets/breadcrumb_widget.dart';
import 'package:anu_app/presentation/pages/product/widgets/product_image_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/product_model.dart';

class ProductDetailsContent extends StatelessWidget {
  final ProductModel product;
  final List<BreadcrumbModel> breadcrumbs;
  final VoidCallback onWishlistToggle;

  const ProductDetailsContent({
    super.key,
    required this.product,
    this.breadcrumbs = const [],
    required this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Product images slider at the top
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs
                if (breadcrumbs.isNotEmpty)
                  BreadcrumbWidget(
                    breadcrumbs: breadcrumbs,
                    onTap: (slug) {
                      if (slug.isEmpty) {
                        // Navigate to home
                        context.go('/home');
                      } else {
                        // Navigate to category page
                        final categoryName = breadcrumbs
                            .firstWhere((b) => b.slug == slug,
                                orElse: () => BreadcrumbModel(
                                    id: '', name: 'Category', slug: slug))
                            .name;
                        context.go(
                            '/products?type=category&title=$categoryName&category=$slug');
                      }
                    },
                  ),

                // Image slider
                ProductImageSlider(images: product.images),

                // Product info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product title and wishlist button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              product.isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: product.isWishlisted
                                  ? const Color(0xFFFF4947)
                                  : Colors.grey,
                            ),
                            onPressed: onWishlistToggle,
                          ),
                        ],
                      ),

                      // Seller name if available
                      if (product.sellerInfo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Sold by: ${product.sellerInfo!.userName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                      // Price section
                      Row(
                        children: [
                          Text(
                            product.formattedSalePrice,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.discountPercentage.isNotEmpty) ...[
                            Text(
                              product.formattedRegularPrice,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stock info
                      Row(
                        children: [
                          Icon(
                            product.stockQuantity > 0
                                ? Icons.check_circle
                                : Icons.error,
                            size: 16,
                            color: product.stockQuantity > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.stockQuantity > 0
                                ? 'In Stock (${product.stockQuantity} available)'
                                : 'Out of Stock',
                            style: TextStyle(
                              color: product.stockQuantity > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description title
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description content
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'No description available for this product.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Brand info
                      if (product.brand.name.isNotEmpty) ...[
                        const Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.brand.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(
                          height: 100), // Extra space for bottom buttons
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons (Add to Cart, Buy Now)
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Add to cart functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to cart'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A2E),
                    side: const BorderSide(color: Color(0xFFFF7A2E)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Buy now functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Buy Now functionality not implemented yet'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Buy Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
