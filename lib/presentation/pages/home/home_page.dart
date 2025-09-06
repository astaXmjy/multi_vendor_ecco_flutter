// lib/presentation/pages/home/home_page.dart
import 'package:anu_app/providers/cart_provider.dart';
import 'package:anu_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/banner_slider.dart';
import 'widgets/categories_section.dart';
import 'widgets/products_section.dart';
import '../shared/custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeData();

// Add this line to load cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoggedIn) {
          Provider.of<CartProvider>(context, listen: false).fetchCartItems();
        }
      }
    });
  }

  Future<void> _initializeData() async {
// Initialize both products and wishlist
    await Future.wait([
      _loadProducts(),
      _initializeWishlist(),
    ]);
  }

  Future<void> _loadProducts() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

// Load all three types of products concurrently
    await Future.wait([
      productProvider.loadFeaturedProducts(),
      productProvider.loadNewArrivals(),
      productProvider.loadBestSellers(),
    ]);
  }

  Future<void> _initializeWishlist() async {
    try {
      final wishlistProvider =
          Provider.of<WishlistProvider>(context, listen: false);
      await wishlistProvider.initialize();
    } catch (e) {
// Silently handle wishlist initialization errors
// User can still use the app without wishlist functionality
      print('Failed to initialize wishlist: $e');
    }
  }

  void _navigateToProductDetails(ProductModel product) {
// Navigate to product details page
    context.push('/product/${product.slug}');
  }

  void _navigateToAllProducts(String title, String type) {
// Navigate to all products page with type (featured, new_arrivals, best_sellers)
    context.push('/products?type=$type&title=$title');
  }

// Updated wishlist handler with API integration
  void _handleWishlistTap(ProductModel product) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    try {
      await productProvider.toggleWishlist(product, context);
    } catch (e) {
// Error handling is done in the ProductProvider
      print('Wishlist toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      drawer: const HomeDrawer(),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
// Banner slider
                  const BannerSlider(),

                  const SizedBox(height: 16),

// Categories section
                  const CategoriesSection(),

                  const SizedBox(height: 16),

// Featured products with API wishlist integration
                  ProductsSection(
                    title: 'Featured Products',
                    products: productProvider.featuredProducts,
                    isLoading: productProvider.isLoadingFeatured,
                    errorMessage: productProvider.featuredError,
                    onProductTap: _navigateToProductDetails,
                    onWishlistTap: _handleWishlistTap,
                    onRetry: productProvider.loadFeaturedProducts,
                    onViewAll: () =>
                        _navigateToAllProducts('Featured Products', 'featured'),
                  ),

                  const SizedBox(height: 16),

// New arrivals with API wishlist integration
                  ProductsSection(
                    title: 'New Arrivals',
                    products: productProvider.newArrivals,
                    isLoading: productProvider.isLoadingNewArrivals,
                    errorMessage: productProvider.newArrivalsError,
                    onProductTap: _navigateToProductDetails,
                    onWishlistTap: _handleWishlistTap,
                    onRetry: productProvider.loadNewArrivals,
                    onViewAll: () =>
                        _navigateToAllProducts('New Arrivals', 'new_arrivals'),
                  ),

                  const SizedBox(height: 16),

// Best sellers with API wishlist integration
                  ProductsSection(
                    title: 'Best Sellers',
                    products: productProvider.bestSellers,
                    isLoading: productProvider.isLoadingBestSellers,
                    errorMessage: productProvider.bestSellersError,
                    onProductTap: _navigateToProductDetails,
                    onWishlistTap: _handleWishlistTap,
                    onRetry: productProvider.loadBestSellers,
                    onViewAll: () =>
                        _navigateToAllProducts('Best Sellers', 'best_sellers'),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}
