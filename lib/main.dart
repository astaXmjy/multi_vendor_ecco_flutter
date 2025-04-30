// lib/main.dart
import 'package:anu_app/api/services/auth_service.dart';
import 'package:anu_app/core/models/profile_model.dart';
import 'package:anu_app/presentation/pages/auth/address_form_page.dart';
import 'package:anu_app/presentation/pages/cart/cart_page.dart';
import 'package:anu_app/presentation/pages/cart/checkout_page.dart';
import 'package:anu_app/presentation/pages/categories/category_tree_products_page.dart';
import 'package:anu_app/presentation/pages/profile/my_addresses_page.dart';
import 'package:anu_app/presentation/pages/profile/widgets/edit_profile_page.dart';
import 'package:anu_app/providers/cart_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/create_account_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/wishlist/wishlist_page.dart';
import 'presentation/pages/categories/combined_categories_page.dart';
import 'presentation/pages/product/product_detail_page.dart';
import 'presentation/pages/product/products_page.dart';
import 'presentation/pages/profile/profile_page.dart';
import 'providers/category_provider.dart';
import 'providers/user_provider.dart';
import 'providers/address_provider.dart';
import 'providers/product_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Create a UserProvider instance that we can initialize early
  final UserProvider _userProvider = UserProvider();
  final AuthService _authService = AuthService();
  bool _initialized = false;
  bool _isAutoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the user provider
      await _userProvider.initialize();

      developer.log('MyApp: UserProvider initialized');

      await _attemptAutoLogin();
    } catch (e) {
      developer.log('MyApp: Error initializing UserProvider - $e');
    } finally {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _attemptAutoLogin() async {
    try {
      // Check if the user is already logged in
      final bool isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // User is already logged in, no need to auto-login
        _isAutoLoginAttempted = true;
        return;
      }

      // Get saved user data
      final userData = await _authService.getUserData();
      final savedPassword = await _authService.getSavedPassword();

      // Check if we have the necessary credentials
      if (userData != null &&
          userData['email'] != null &&
          userData['email'].isNotEmpty &&
          savedPassword != null &&
          savedPassword.isNotEmpty) {
        // Attempt to login with saved credentials
        final loginResult =
            await _authService.login(userData['email'], savedPassword);

        if (loginResult['success']) {
          // Login successful - Update UserProvider
          _userProvider.processLoginData(loginResult['data']);
          _isAutoLoginAttempted = true;
        }
      }
    } catch (e) {
      developer.log('Error during auto-login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // show loading screen until initialized

    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFFF7A2E)),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          ),
        ),
      );
    }

    // Create the router configuration with initial location based on login status
    final String initialLocation =
        _userProvider.isLoggedIn ? '/home' : '/login';

    // Create the router configuration
// In main.dart, update the GoRouter configuration
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/create-account',
          builder: (context, state) => const CreateAccountPage(),
        ),
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
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) {
            final profileData = state.extra as ProfileModel?;
            return EditProfilePage(profile: profileData!);
          },
        ),
        GoRoute(
          path: '/profile/addresses',
          builder: (context, state) => const MyAddressesPage(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CombinedCategoriesPage(),
        ),
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
        GoRoute(
          path: '/category-products/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            final title =
                state.uri.queryParameters['title'] ?? 'Category Products';
            // You may also want to pass breadcrumbs through state.extra
            return CategoryTreeProductsPage(
              categorySlug: slug,
              title: title,
            );
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    );

    // Wrap the app with providers for state management
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        // Use the already initialized user provider
        ChangeNotifierProvider.value(value: _userProvider),
        // Add address provider
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        // Add product provider
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        // Add cart provider
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp.router(
        title: 'Anugami E-commerce',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFFF7A2E),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF7A2E),
            primary: const Color(0xFFFF7A2E),
            secondary: const Color(0xFFFF4947),
          ),
          fontFamily: 'Poppins', // If you're using a custom font
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF7A2E)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A2E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
