// lib/main.dart
import 'package:anu_app/providers/review_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'api/services/auth_service.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/category_provider.dart';
import 'providers/user_provider.dart';
import 'providers/address_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Create providers that we can initialize early
  final UserProvider _userProvider = UserProvider();
  final AuthService _authService = AuthService();
  bool _initialized = false;
  bool _isAutoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes if needed
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        break;
      case AppLifecycleState.paused:
        // App is in background
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
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
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
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
    // Show loading screen until initialized
    if (!_initialized) {
      return MaterialApp(
        title: 'Anugami E-commerce',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Icon(
                    Icons.shopping_bag,
                    size: 80,
                    color: Color(0xFFFEAF4E),
                  ),
                  SizedBox(height: 24),

                  // App Name
                  Text(
                    'Anugami',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEAF4E),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Loading indicator
                  CircularProgressIndicator(
                    color: Color(0xFFFEAF4E),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),

                  // Loading text
                  Text(
                    'Initializing...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    // ✅ REMOVED: Don't create router here anymore
    // final router = AppRoutes.createRouter(isLoggedIn: _userProvider.isLoggedIn);

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
        // Add wishlist provider
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        // Add review provider
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],

      // ✅ NEW: Wrap MaterialApp.router with Consumer
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // ✅ Router is rebuilt whenever userProvider.notifyListeners() is called
          return MaterialApp.router(
            title: 'Anugami E-commerce',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,

            // ✅ NEW: Create router here with refreshListenable
            routerConfig: AppRoutes.createRouter(
              isLoggedIn: userProvider.isLoggedIn,
              refreshListenable:
                  userProvider, // 🎯 This makes the magic happen!
            ),

            // Global scaffold messenger for showing snackbars across the app
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),

            // Builder to handle global UI modifications
            builder: (context, child) {
              // Handle responsive design and orientation
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Ensure text scaling doesn't exceed reasonable limits
                  textScaleFactor:
                      MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

// Global error handler widget
class GlobalErrorHandler extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const GlobalErrorHandler({
    Key? key,
    required this.child,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: AppTheme.getResponsivePadding(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: AppTheme.getTitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.getBodyFontSize(context),
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app or navigate to home
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
