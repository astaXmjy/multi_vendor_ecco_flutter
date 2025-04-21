// lib/presentation/pages/home/widgets/home_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../profile/my_addresses_page.dart';
import 'drawer_item.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get user data from provider
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final fullName = userProvider.fullName;
    final email = userProvider.email;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF7A2E), // Orange
                  Color(0xFFFF4947), // Coral
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Color(0xFFFF7A2E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLoggedIn ? 'Welcome, $fullName' : 'Welcome, Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoggedIn && email.isNotEmpty
                      ? email
                      : 'Sign in to continue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          DrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              }),
          DrawerItem(
              icon: Icons.category,
              title: 'Categories',
              onTap: () {
                Navigator.pop(context);
                context.go('/categories');
              }),
          DrawerItem(
              icon: Icons.shopping_bag,
              title: 'My Orders',
              onTap: () {
                // Navigate to orders page
                Navigator.pop(context);
              }),
          DrawerItem(
              icon: Icons.favorite,
              title: 'Wishlist',
              onTap: () {
                Navigator.pop(context);
                context.go('/wishlist');
              }),
          DrawerItem(
              icon: Icons.person,
              title: 'My Profile',
              onTap: () {
                // Navigate to profile page
                Navigator.pop(context);
              }),
          DrawerItem(
              icon: Icons.location_on,
              title: 'My Addresses',
              onTap: () {
                // Navigate to addresses page
                Navigator.pop(context);

                // Check if user is logged in
                if (!isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to manage your addresses'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.go('/login');
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyAddressesPage(),
                  ),
                );
              }),
          const Divider(),
          DrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // Navigate to settings page
                Navigator.pop(context);
              }),
          DrawerItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help page
                Navigator.pop(context);
              }),
          // Show login/logout based on authentication state
          isLoggedIn
              ? DrawerItem(
                  icon: Icons.exit_to_app,
                  title: 'Logout',
                  onTap: () async {
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'Are you sure you want to logout?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      // Perform logout
                      Navigator.pop(context); // Close drawer
                      await userProvider.logout();
                      // Navigate to login screen
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                )
              : DrawerItem(
                  icon: Icons.login,
                  title: 'Login',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                ),
        ],
      ),
    );
  }
}
