// lib/presentation/pages/home/widgets/categories_section.dart
import 'package:flutter/material.dart';
import '../../../../api/services/category_service.dart';
import '../../../../core/models/category_model.dart';
import 'section_title.dart';

class CategoriesSection extends StatefulWidget {
  final Function(CategoryModel)? onCategoryTap;
  
  const CategoriesSection({
    Key? key,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Get featured categories or menu categories
      final categories = await _categoryService.getFeaturedCategories();
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/categories');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFFFF7A2E),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildCategoriesContent(),
      ],
    );
  }

  Widget _buildCategoriesContent() {
    if (_isLoading) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFF7A2E),
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Failed to load categories: $_error',
            style: TextStyle(color: Colors.red[400]),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryItem(
            category: category,
            onTap: () {
              if (widget.onCategoryTap != null) {
                widget.onCategoryTap!(category);
              } else {
                // Default navigation
                Navigator.pushNamed(
                  context, 
                  '/products',
                  arguments: {'categoryId': category.id, 'categoryName': category.name},
                );
              }
            },
          );
        },
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryItem({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildCategoryIcon(),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    // First try to use icon_url if available
    if (category.iconUrl != null && category.iconUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          category.iconUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If icon_url fails, try image_url
            return _buildImageOrFallback();
          },
        ),
      );
    }
    
    return _buildImageOrFallback();
  }
  
  Widget _buildImageOrFallback() {
    // Try to use image_url if available
    if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          category.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if both URLs fail
            return _buildFallbackIcon();
          },
        ),
      );
    }
    
    // Otherwise use the fallback icon
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        _getCategoryIcon(),
        color: const Color(0xFFFF7A2E),
        size: 30,
      ),
    );
  }

  IconData _getCategoryIcon() {
    final categoryName = category.name.toLowerCase();

    if (categoryName.contains('men') ||
        categoryName.contains('shirt') ||
        categoryName.contains('clothing')) {
      return Icons.checkroom;
    } else if (categoryName.contains('electronic') ||
        categoryName.contains('device') ||
        categoryName.contains('tech')) {
      return Icons.devices;
    } else if (categoryName.contains('food') ||
        categoryName.contains('grocery') ||
        categoryName.contains('fruit')) {
      return Icons.shopping_basket;
    } else if (categoryName.contains('home') ||
        categoryName.contains('living') ||
        categoryName.contains('furniture') ||
        categoryName.contains('decor')) {
      return Icons.home;
    } else if (categoryName.contains('beauty') ||
        categoryName.contains('makeup') ||
        categoryName.contains('cosmetic')) {
      return Icons.face;
    } else if (categoryName.contains('sport') ||
        categoryName.contains('fitness') ||
        categoryName.contains('exercise')) {
      return Icons.sports_soccer;
    }

    // Default icon
    return Icons.category;
  }
}