// lib/presentation/pages/wishlist/wishlist_page.dart
import 'package:flutter/material.dart';
import '../home/widgets/home_app_bar.dart';
import '../home/widgets/custom_bottom_nav.dart';
import 'widgets/wishlist_item_card.dart';
import 'widgets/empty_wishlist.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadWishlistItems();
  }

  Future<void> _loadWishlistItems() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes - replace with your actual data fetching
    final items = getSampleWishlistItems();

    if (mounted) {
      setState(() {
        _wishlistItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    setState(() {
      _wishlistItems.removeWhere((item) => item['id'] == productId);
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from wishlist'),
        duration: Duration(seconds: 2),
      ),
    );

    // Implement actual removal logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadWishlistItems,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wishlistItems.isEmpty
                ? const EmptyWishlist()
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'My Wishlist',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${_wishlistItems.length} items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _wishlistItems.length,
                            itemBuilder: (context, index) {
                              final item = _wishlistItems[index];
                              return WishlistItemCard(
                                id: item['id'],
                                name: item['name'],
                                price: item['price'],
                                discount: item['discount'],
                                imageUrl: item['image'],
                                inStock: item['inStock'],
                                onRemove: () => _removeFromWishlist(item['id']),
                                onAddToCart: () {
                                  // Implement add to cart functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  // Sample data - to be replaced with your actual data source
  List<Map<String, dynamic>> getSampleWishlistItems() {
    return [
      {
        'id': '1',
        'name': 'Wireless Earbuds with Noise Cancellation',
        'price': '₹1,499',
        'image': 'assets/images/product1.jpg',
        'discount': '25%',
        'inStock': true,
      },
      {
        'id': '2',
        'name': 'Smart Watch with Heart Rate Monitor',
        'price': '₹2,999',
        'image': 'assets/images/product2.jpg',
        'discount': '10%',
        'inStock': true,
      },
      {
        'id': '3',
        'name': 'Bluetooth Speaker Waterproof',
        'price': '₹1,299',
        'image': 'assets/images/product3.jpg',
        'discount': '30%',
        'inStock': false,
      },
      {
        'id': '4',
        'name': 'Fitness Tracker with SpO2 Monitor',
        'price': '₹1,999',
        'image': 'assets/images/product4.jpg',
        'discount': '15%',
        'inStock': true,
      },
    ];
  }
}
