// lib/presentation/pages/home/widgets/home_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'drawer_item.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Welcome, User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'user@example.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          DrawerItem(icon: Icons.home, title: 'Home', onTap: () {}),
          DrawerItem(icon: Icons.category, title: 'Categories', onTap: () {}),
          DrawerItem(icon: Icons.shopping_bag, title: 'My Orders', onTap: () {}),
          DrawerItem(icon: Icons.favorite, title: 'Wishlist', onTap: () {}),
          DrawerItem(icon: Icons.person, title: 'My Profile', onTap: () {}),
          DrawerItem(icon: Icons.location_on, title: 'My Addresses', onTap: () {}),
          const Divider(),
          DrawerItem(icon: Icons.settings, title: 'Settings', onTap: () {}),
          DrawerItem(icon: Icons.help, title: 'Help & Support', onTap: () {}),
          DrawerItem(
              icon: Icons.exit_to_app,
              title: 'Logout',
              onTap: () {
                // Implement logout
                context.go('/login');
              }
          ),
        ],
      ),
    );
  }
}