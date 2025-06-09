// lib/presentation/pages/product/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/breadcrumb_model.dart';
import '../../../providers/product_provider.dart';
import '../shared/custom_app_bar.dart';
import 'enhanced_product_details_content.dart';

class ProductDetailPage extends StatefulWidget {
  final String slug;

  const ProductDetailPage({
    Key? key,
    required this.slug,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<BreadcrumbModel> _breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadProductDetails());
  }

  // Load category details for breadcrumbs
  Future<void> _loadCategoryDetails(String categorySlug) async {
    try {
      final CategoryService categoryService = CategoryService();
      final result = await categoryService.getCategoryBySlug(categorySlug);

      if (result['success'] && result['data'] != null && mounted) {
        final data = result['data'];
        if (data['breadcrumb'] != null) {
          setState(() {
            _breadcrumbs = List<BreadcrumbModel>.from(
              (data['breadcrumb'] as List).map(
                (item) => BreadcrumbModel.fromJson(item),
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading category details: $e');
    }
  }

  // Navigate to category
  void _navigateToCategory(String slug) {
    if (slug.isEmpty) {
      // Navigate to home
      context.go('/home');
    } else {
      // Navigate to category products
      final categoryName = _breadcrumbs
          .firstWhere((b) => b.slug == slug,
              orElse: () =>
                  BreadcrumbModel(id: '', name: 'Category', slug: slug))
          .name;
      context.push('/products?category=$slug&title=$categoryName');
    }
  }

  Future<void> _loadProductDetails() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    // Load product details with variants
    await productProvider.loadProductDetailsWithVariants(widget.slug);

    // After product loads, fetch category details
    if (mounted && productProvider.selectedProduct != null) {
      final categorySlug = productProvider.selectedProduct!.category;
      if (categorySlug.isNotEmpty) {
        _loadCategoryDetails(categorySlug);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Product Details',
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share functionality not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Show loading state
          if (productProvider.isLoadingProductDetails) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF7A2E),
                  ),
                  SizedBox(height: 16),
                  Text('Loading product details...'),
                ],
              ),
            );
          }

          // Show error state
          if (productProvider.productDetailsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      'Failed to load product details',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productProvider.productDetailsError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadProductDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A2E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return const Center(
              child: Text('Product not found'),
            );
          }

          // Show variants loading indicator if still loading
          Widget content = EnhancedProductDetailsContent(
            product: product,
            variantData: productProvider.selectedProductVariants,
            breadcrumbs: _breadcrumbs,
            onWishlistToggle: () async {
              await Provider.of<ProductProvider>(context, listen: false)
                  .toggleWishlist(product, context);
            },
          );

          // Overlay loading indicator for variants if needed
          if (productProvider.isLoadingVariants) {
            content = Stack(
              children: [
                content,
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading variants...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Show variant error if exists (non-critical)
          if (productProvider.variantsError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not load product variants: ${productProvider.variantsError}',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        productProvider.loadProductVariants(widget.slug);
                      },
                    ),
                  ),
                );
              }
            });
          }

          return content;
        },
      ),
    );
  }

  @override
  void dispose() {
    // Clear selected product data when leaving the page
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearSelectedProduct();
    super.dispose();
  }
}
