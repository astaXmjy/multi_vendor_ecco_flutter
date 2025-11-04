// lib/presentation/pages/categories/combined_categories_page.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/main.dart';
import 'package:anu_app/presentation/pages/categories/category_tree_products_page.dart';
import 'package:anu_app/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/animated_category_list.dart';
import 'widgets/category_grid_item.dart';

class CombinedCategoriesPage extends StatefulWidget {
  const CombinedCategoriesPage({Key? key}) : super(key: key);

  @override
  State<CombinedCategoriesPage> createState() => _CombinedCategoriesPageState();
}

class _CombinedCategoriesPageState extends State<CombinedCategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _error;
  bool _isGridView = true; // Default to grid view

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the tree structure for hierarchical display
      final categories = await _categoryService.getCategoryTree();

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
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Categories',
        showBackButton: true,
        actions: [
          // View toggle button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip:
                _isGridView ? 'Switch to List View' : 'Switch to Grid View',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _buildBody(),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGradient.colors[1],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _loadCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    // Show either grid or list view based on the selected view type
    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return CategoryGridItem(
          category: _categories[index],
          onTap: _navigateToCategory,
        );
      },
    );
  }

  Widget _buildListView() {
    return AnimatedCategoryList(
      categories: _categories,
      onCategoryTap: _navigateToCategory,
    );
  }

  void _navigateToCategory(CategoryModel category) {
    // Set this category as the root of breadcrumbs
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    // Navigate to the category tree products page
    context.push('/category-products/${category.slug}?title=${category.name}');
  }
}

// Subcategory page to display children of a selected category
class SubcategoryPage extends StatelessWidget {
  final CategoryModel parentCategory;

  const SubcategoryPage({
    Key? key,
    required this.parentCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: parentCategory.name,
        showBackButton: true,
      ),
      body: parentCategory.children.isEmpty
          ? const Center(child: Text('No subcategories found'))
          : ListView.builder(
              itemCount: parentCategory.children.length,
              itemBuilder: (context, index) {
                final subcategory = parentCategory.children[index];
                return ListTile(
                  leading: subcategory.imageUrl != null
                      ? Image.network(
                          subcategory.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => Icon(
                            Icons.category,
                            color: AppTheme.primaryGradient.colors[1],
                          ),
                        )
                      : Icon(
                          Icons.category,
                          color: AppTheme.primaryGradient.colors[1],
                        ),
                  title: Text(
                    subcategory.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${subcategory.productCount} products',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.primaryGradient.colors[1],
                  ),
                  onTap: () {
                    if (subcategory.children.isNotEmpty) {
                      // If this subcategory has children, navigate to a new subcategory page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubcategoryPage(
                            parentCategory: subcategory,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to the category tree products page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTreeProductsPage(
                            categorySlug: subcategory.slug,
                            title: subcategory.name,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
