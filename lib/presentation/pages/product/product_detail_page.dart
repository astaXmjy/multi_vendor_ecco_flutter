// lib/presentation/pages/product/product_detail_page.dart
import 'package:anu_app/api/services/category_service.dart';
import 'package:anu_app/core/models/breadcrumb_model.dart';
import 'package:go_router/go_router.dart';
import 'package:anu_app/presentation/pages/product/product_details_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/product_provider.dart';
import '../shared/custom_app_bar.dart';

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
    await productProvider.loadProductDetails(widget.slug);

    // After product loads, fetch category details
    if (mounted && productProvider.selectedProduct != null) {
      final categorySlug = productProvider.selectedProduct!.category;
      if (categorySlug.isNotEmpty) {
        print(categorySlug);
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
          if (productProvider.isLoadingProductDetails) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF7A2E),
              ),
            );
          }

          if (productProvider.productDetailsError != null) {
            return Center(
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
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return const Center(
              child: Text('Product not found'),
            );
          }

          return ProductDetailsContent(
            product: product,
            breadcrumbs: _breadcrumbs,
            onWishlistToggle: () => productProvider.toggleWishlist(product),
          );
        },
      ),
    );
  }
}
