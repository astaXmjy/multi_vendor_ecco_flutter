// lib/main.dart
import 'package:anu_app/presentation/pages/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/create_account_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/wishlist/wishlist_page.dart';
import 'presentation/pages/categories/combined_categories_page.dart';
import 'providers/category_provider.dart';
import 'providers/user_provider.dart';
import 'providers/address_provider.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

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
  bool _initialized = false;

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
    } catch (e) {
      developer.log('MyApp: Error initializing UserProvider - $e');
    } finally {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create the router configuration
    final router = GoRouter(
      initialLocation: '/login',
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
          builder: (context, state) => const CreateAccountPage(),
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
          path: '/categories',
          builder: (context, state) => const CombinedCategoriesPage(),
        ),
      ],
    );

    // Show loading screen until initialized
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Color(0xFFFF7A2E)),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          ),
        ),
      );
    }

    // Wrap the app with providers for state management
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        // Use the already initialized user provider
        ChangeNotifierProvider.value(value: _userProvider),
        // Add address provider
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        // Add other providers here as needed
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
