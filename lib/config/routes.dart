// lib/config/routes.dart
import 'package:anu_app/presentation/widgets/reviews/review_form.dart';
import 'package:anu_app/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/create_account_page.dart';
import '../presentation/pages/auth/address_form_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/wishlist/wishlist_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/profile/my_addresses_page.dart';
import '../presentation/pages/profile/widgets/edit_profile_page.dart';
import '../presentation/pages/categories/combined_categories_page.dart';
import '../presentation/pages/categories/category_tree_products_page.dart';
import '../presentation/pages/product/product_detail_page.dart';
import '../presentation/pages/product/products_page.dart';
import '../presentation/pages/cart/cart_page.dart';
import '../presentation/pages/cart/checkout_page.dart';
import '../core/models/profile_model.dart';
import '../presentation/pages/orders/orders_page.dart';

class AppRoutes {
  static GoRouter createRouter({required bool isLoggedIn}) {
    return GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/login',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isLoginRoute = state.matchedLocation == '/login';
        final isCreateAccountRoute = state.matchedLocation == '/create-account';

        // Get current auth state from provider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentAuthState = userProvider.isLoggedIn;

        // If auth state changed, update accordingly
        if (currentAuthState != isLoggedIn) {
          return currentAuthState ? '/home' : '/login';
        }

        // Original redirect logic
        if (!isLoggedIn && !isLoginRoute && !isCreateAccountRoute) {
          return '/login';
        }
        if (isLoggedIn && (isLoginRoute || isCreateAccountRoute)) {
          return '/home';
        }
        return null;
      },
      routes: [
        // Authentication Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/create-account',
          name: 'create-account',
          builder: (context, state) => const CreateAccountPage(),
        ),

        // Address Form Route
        GoRoute(
          path: '/address-form',
          name: 'address-form',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'] ?? 'newAddress';
            final fullName = state.uri.queryParameters['fullName'];
            final phone = state.uri.queryParameters['phone'];

            AddressFormMode addressMode;
            if (mode == 'registration') {
              addressMode = AddressFormMode.registration;
            } else if (mode == 'editAddress') {
              addressMode = AddressFormMode.editAddress;
            } else {
              addressMode = AddressFormMode.newAddress;
            }

            return AddressFormPage(
              mode: addressMode,
              fullName: fullName,
              phone: phone,
            );
          },
        ),

        // Main App Routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          builder: (context, state) => const WishlistPage(),
        ),

        // Profile Routes
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/profile/edit',
          name: 'profile-edit',
          builder: (context, state) {
            final profileData = state.extra as ProfileModel?;
            if (profileData == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Profile data not found'),
                ),
              );
            }
            return EditProfilePage(profile: profileData);
          },
        ),
        GoRoute(
          path: '/profile/addresses',
          name: 'profile-addresses',
          builder: (context, state) => const MyAddressesPage(),
        ),

        // Category Routes
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (context, state) => const CombinedCategoriesPage(),
        ),
        GoRoute(
          path: '/category-products/:slug',
          name: 'category-products',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            final title =
                state.uri.queryParameters['title'] ?? 'Category Products';
            return CategoryTreeProductsPage(
              categorySlug: slug,
              title: title,
            );
          },
        ),

        // Product Routes
        GoRoute(
          path: '/product/:slug',
          name: 'product-detail',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return ProductDetailPage(slug: slug);
          },
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? '';
            final title = state.uri.queryParameters['title'] ?? 'Products';
            final category = state.uri.queryParameters['category'];
            return ProductsPage(
              type: type,
              title: title,
              categorySlug: category,
            );
          },
        ),

        // Cart Routes
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutPage(),
        ),

        // Orders Routes (New - Add these)
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersPage(),
        ),

        // Search Route
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            final query = state.uri.queryParameters['q'] ?? '';
            return ProductsPage(
              type: 'search',
              title: 'Search Results',
              // You might want to add search functionality to ProductsPage
            );
          },
        ),
        // Review Routes
        GoRoute(
          path: '/product/:slug/review',
          name: 'write-review',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return ReviewForm(
              productSlug: slug,
              onSuccess: () {
                context.pop();
              },
            );
          },
        ),
        //   ],
        // );
      ],

      // Error handling with better UX
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: const Color(0xFFFF7A2E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Page Not Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The page "${state.matchedLocation}" could not be found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Go Home'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF7A2E),
                        side: const BorderSide(color: Color(0xFFFF7A2E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Cart'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation helper methods for better code organization
  static void goToCart(BuildContext context) {
    context.go('/cart');
  }

  static void goToCheckout(BuildContext context) {
    context.go('/checkout');
  }

  static void goToProduct(BuildContext context, String slug) {
    context.go('/product/$slug');
  }

  static void goToOrders(BuildContext context) {
    context.go('/orders');
  }

  static void goToCategory(BuildContext context, String slug, String title) {
    context.go('/category-products/$slug?title=${Uri.encodeComponent(title)}');
  }

  static void goToProducts(
    BuildContext context, {
    String type = '',
    String title = 'Products',
    String? category,
  }) {
    var uri =
        '/products?type=${Uri.encodeComponent(type)}&title=${Uri.encodeComponent(title)}';
    if (category != null) {
      uri += '&category=${Uri.encodeComponent(category)}';
    }
    context.go(uri);
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToWishlist(BuildContext context) {
    context.go('/wishlist');
  }

  static void goToHome(BuildContext context) {
    context.go('/home');
  }

  static void goToSearch(BuildContext context, String query) {
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }

  // Back navigation with fallback
  static void goBack(BuildContext context, {String fallbackRoute = '/home'}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }
}
