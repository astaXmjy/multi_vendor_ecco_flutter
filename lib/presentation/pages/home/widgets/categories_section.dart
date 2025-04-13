// lib/presentation/pages/home/widgets/categories_section.dart
import 'package:flutter/material.dart';
import 'section_title.dart';
import 'category_item.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample category data
    final List<Map<String, dynamic>> categories = [
      {'name': 'Fashion', 'icon': Icons.checkroom},
      {'name': 'Electronics', 'icon': Icons.devices},
      {'name': 'Groceries', 'icon': Icons.shopping_basket},
      {'name': 'Home', 'icon': Icons.home},
      {'name': 'Beauty', 'icon': Icons.face},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Shop by Category',
          onViewAll: () {
            // Navigate to all categories
          },
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return CategoryItem(
                name: categories[index]['name'],
                icon: categories[index]['icon'],
                onTap: () {
                  // Navigate to category
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
