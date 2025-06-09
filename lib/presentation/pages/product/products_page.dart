// lib/presentation/pages/product/products_page.dart
import 'package:anu_app/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/product_list_item.dart';
import 'package:go_router/go_router.dart';

class ProductsPage extends StatefulWidget {
  final String title;
  final String
      type; // 'featured', 'new_arrivals', 'best_sellers', or empty for all
  final String? categorySlug;

  const ProductsPage({
    Key? key,
    required this.title,
    required this.type,
    this.categorySlug,
  }) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (widget.categorySlug != null) {
      // Load products by category
      await productProvider.loadProductsByCategory(widget.categorySlug!);
    } else {
      // Load products by type
      switch (widget.type) {
        case 'featured':
          await productProvider.loadFeaturedProducts();
          break;
        case 'new_arrivals':
          await productProvider.loadNewArrivals();
          break;
        case 'best_sellers':
          await productProvider.loadBestSellers();
          break;
        default:
          // Load all products or by default sorting
          await productProvider.getProducts();
          break;
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    // Only implement pagination for category products for now
    if (widget.categorySlug != null) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      if (!productProvider.isLoadingCategory &&
          productProvider.hasMoreCategoryProducts) {
        await productProvider.loadMoreCategoryProducts(widget.categorySlug!);
      }
    }
  }

  void _navigateToProductDetails(ProductModel product) {
    context.push('/product/${product.slug}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
        actions: [
          // View toggle button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // Filter button
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              // Show filter options
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Determine which product list to show based on the type or category
          List<ProductModel> products = [];
          bool isLoading = false;
          String? errorMessage;

          if (widget.categorySlug != null) {
            products = productProvider.categoryProducts;
            isLoading = productProvider.isLoadingCategory;
            errorMessage = productProvider.categoryError;
          } else {
            switch (widget.type) {
              case 'featured':
                products = productProvider.featuredProducts;
                isLoading = productProvider.isLoadingFeatured;
                errorMessage = productProvider.featuredError;
                break;
              case 'new_arrivals':
                products = productProvider.newArrivals;
                isLoading = productProvider.isLoadingNewArrivals;
                errorMessage = productProvider.newArrivalsError;
                break;
              case 'best_sellers':
                products = productProvider.bestSellers;
                isLoading = productProvider.isLoadingBestSellers;
                errorMessage = productProvider.bestSellersError;
                break;
              default:
                products = productProvider.allProducts;
                isLoading = productProvider.isLoadingAllProducts;
                errorMessage = productProvider.allProductsError;
                break;
            }
          }

          // Show loading state
          if (isLoading && products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF7A2E),
              ),
            );
          }

          // Show error state
          if (errorMessage != null && products.isEmpty) {
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
                    'Failed to load products',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadProducts,
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

          // Show empty state
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing your search or filter options',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          // Show product list/grid
          return RefreshIndicator(
            onRefresh: _loadProducts,
            color: const Color(0xFFFF7A2E),
            child: Column(
              children: [
                // Products count and sort options
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Show sort options
                          _showSortOptions(context);
                        },
                        child: Row(
                          children: const [
                            Text(
                              'Sort',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.sort,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Products list/grid
                Expanded(
                  child: _isGridView
                      ? _buildProductGrid(products, productProvider)
                      : _buildProductList(products, productProvider),
                ),

                // Loading indicator at the bottom for pagination
                if (widget.categorySlug != null &&
                    productProvider.isLoadingCategory &&
                    products.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductModel> products, ProductProvider productProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Adjusted to give more vertical space
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductGridItem(
          product: products[index],
          onTap: () => _navigateToProductDetails(products[index]),
          onWishlistTap: () => productProvider.toggleWishlist(products[index]),
        );
      },
    );
  }

  Widget _buildProductList(
      List<ProductModel> products, ProductProvider productProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductListItem(
          product: products[index],
          onTap: () => _navigateToProductDetails(products[index]),
          onWishlistTap: () => productProvider.toggleWishlist(products[index]),
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Price: High to Low'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Price: Low to High'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.new_releases),
              title: const Text('Newest First'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Popularity'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Filter Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price slider would go here

                      const SizedBox(height: 24),
                      const Text(
                        'Brand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Brand checkboxes would go here

                      const SizedBox(height: 24),
                      const Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rating options would go here
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Apply filters
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A2E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
