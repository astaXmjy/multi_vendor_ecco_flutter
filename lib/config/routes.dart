// lib/config/routes.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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

class AppRoutes {
  static GoRouter createRouter({required bool isLoggedIn}) {
    return GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/login',
      routes: [
        // Authentication Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/create-account',
          builder: (context, state) => const CreateAccountPage(),
        ),

        // Address Form Route
        GoRoute(
          path: '/address-form',
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
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistPage(),
        ),

        // Profile Routes
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/profile/edit',
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
          builder: (context, state) => const MyAddressesPage(),
        ),

        // Category Routes
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CombinedCategoriesPage(),
        ),
        GoRoute(
          path: '/category-products/:slug',
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
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return ProductDetailPage(slug: slug);
          },
        ),
        GoRoute(
          path: '/products',
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
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: const Color(0xFFFF7A2E),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
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
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),

      // Redirect handling
      redirect: (context, state) {
        // Add any authentication or conditional redirects here
        return null;
      },
    );
  }
}
