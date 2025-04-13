// lib/presentation/pages/home/widgets/products_section.dart
import 'package:flutter/material.dart';
import 'section_title.dart';
import 'product_card.dart';

class ProductsSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> products;
  final VoidCallback? onViewAll;

  const ProductsSection({
    Key? key,
    required this.title,
    required this.products,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title,
          onViewAll: onViewAll,
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                name: products[index]['name'],
                price: products[index]['price'],
                imageUrl: products[index]['image'],
                discount: products[index]['discount'],
                onTap: () {
                  // Navigate to product details
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
