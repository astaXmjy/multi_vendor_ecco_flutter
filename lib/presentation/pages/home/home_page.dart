// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/banner_slider.dart';
import 'widgets/categories_section.dart';
import 'widgets/products_section.dart';
import '../shared//custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      drawer: const HomeDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
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

              // Featured products
              ProductsSection(
                title: 'Featured Products',
                products: getSampleProducts(),
              ),

              const SizedBox(height: 16),

              // New arrivals
              ProductsSection(
                title: 'New Arrivals',
                products: getSampleProducts(),
              ),

              const SizedBox(height: 16),

              // Best sellers
              ProductsSection(
                title: 'Best Sellers',
                products: getSampleProducts(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 0,
      ),
    );
  }

  // Sample data provider - in a real app, you'd get this from an API
  List<Map<String, dynamic>> getSampleProducts() {
    return [
      {
        'name': 'Wireless Earbuds',
        'price': '₹1,499',
        'image': 'assets/images/product1.jpg',
        'discount': '25%'
      },
      {
        'name': 'Smart Watch',
        'price': '₹2,999',
        'image': 'assets/images/product2.jpg',
        'discount': '10%'
      },
      {
        'name': 'Bluetooth Speaker',
        'price': '₹1,299',
        'image': 'assets/images/product3.jpg',
        'discount': '30%'
      },
      {
        'name': 'Fitness Tracker',
        'price': '₹1,999',
        'image': 'assets/images/product4.jpg',
        'discount': '15%'
      },
    ];
  }
}
