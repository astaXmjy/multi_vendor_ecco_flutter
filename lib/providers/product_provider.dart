// lib/providers/product_provider.dart
import 'package:anu_app/api/services/category_service.dart';
import 'package:anu_app/core/models/category_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../api/services/product_service.dart';
import '../core/models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  // Product lists
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _newArrivals = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _categoryProducts = [];
  List<ProductModel> _allProducts = [];

  // Loading states
  bool _isLoadingFeatured = false;
  bool _isLoadingNewArrivals = false;
  bool _isLoadingBestSellers = false;
  bool _isLoadingSearch = false;
  bool _isLoadingCategory = false;
  bool _isLoadingAllProducts = false;

  // Error messages
  String? _featuredError;
  String? _newArrivalsError;
  String? _bestSellersError;
  String? _searchError;
  String? _categoryError;
  String? _allProductsError;

  // Pagination data
  int _categoryTotalCount = 0;
  String? _categoryNextPage;
  String? _categoryPreviousPage;

  // Currently selected product
  ProductModel? _selectedProduct;
  bool _isLoadingProductDetails = false;
  String? _productDetailsError;

  // Getters
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get newArrivals => _newArrivals;
  List<ProductModel> get bestSellers => _bestSellers;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get categoryProducts => _categoryProducts;
  List<ProductModel> get allProducts => _allProducts;

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingNewArrivals => _isLoadingNewArrivals;
  bool get isLoadingBestSellers => _isLoadingBestSellers;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingCategory => _isLoadingCategory;
  bool get isLoadingAllProducts => _isLoadingAllProducts;

  String? get featuredError => _featuredError;
  String? get newArrivalsError => _newArrivalsError;
  String? get bestSellersError => _bestSellersError;
  String? get searchError => _searchError;
  String? get categoryError => _categoryError;
  String? get allProductsError => _allProductsError;

  int get categoryTotalCount => _categoryTotalCount;
  bool get hasMoreCategoryProducts => _categoryNextPage != null;

  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoadingProductDetails => _isLoadingProductDetails;
  String? get productDetailsError => _productDetailsError;

  // Add these properties and methods to your ProductProvider class

  // Breadcrumbs for category navigation
  List<CategoryModel> _categoryBreadcrumbs = [];

  // Getter for breadcrumbs
  List<CategoryModel> get categoryBreadcrumbs => _categoryBreadcrumbs;

  // Set breadcrumbs
  void setCategoryBreadcrumbs(List<CategoryModel> breadcrumbs) {
    _categoryBreadcrumbs = breadcrumbs;
    notifyListeners();
  }

  // Add category to breadcrumbs
  void addCategoryToBreadcrumbs(CategoryModel category) {
    if (!_categoryBreadcrumbs.any((item) => item.id == category.id)) {
      _categoryBreadcrumbs.add(category);
      notifyListeners();
    }
  }

  // Set breadcrumbs up to a specific index
  void setBreadcrumbsUpToIndex(int index) {
    if (index >= 0 && index < _categoryBreadcrumbs.length) {
      _categoryBreadcrumbs = _categoryBreadcrumbs.sublist(0, index + 1);
      notifyListeners();
    }
  }

  // Clear breadcrumbs
  void clearBreadcrumbs() {
    _categoryBreadcrumbs = [];
    notifyListeners();
  }

  // Load category with breadcrumb info
  Future<void> loadCategoryWithBreadcrumbs(String slug) async {
    try {
      final categoryService = CategoryService();
      final result = await categoryService.getCategoryBySlug(slug);

      if (result['success'] && result['data'] != null) {
        // Check if there's breadcrumb info in the response
        if (result['data']['breadcrumb'] != null &&
            result['data']['breadcrumb'] is List) {
          final breadcrumbData = result['data']['breadcrumb'] as List;
          final breadcrumbs = breadcrumbData
              .map((item) => CategoryModel.fromJson(item))
              .toList();

          // Add current category if not already included
          final currentCategory = CategoryModel.fromJson(result['data']);
          if (!breadcrumbs.any((item) => item.id == currentCategory.id)) {
            breadcrumbs.add(currentCategory);
          }

          setCategoryBreadcrumbs(breadcrumbs);
        } else {
          // If no breadcrumb info, just use the current category
          final currentCategory = CategoryModel.fromJson(result['data']);
          setCategoryBreadcrumbs([currentCategory]);
        }
      }
    } catch (e) {
      print('Error loading category breadcrumbs: $e');
    }
  }

  // Add to the top with other properties
  // Update the ProductProvider class with additional methods and properties

  // Add to the top with other properties
  List<ProductModel> _categoryTreeProducts = [];
  List<CategoryModel> _categoryTreeSubcategories = [];
  bool _isLoadingCategoryTree = false;
  String? _categoryTreeError;

  // Add to getters
  List<ProductModel> get categoryTreeProducts => _categoryTreeProducts;
  List<CategoryModel> get categoryTreeSubcategories =>
      _categoryTreeSubcategories;
  bool get isLoadingCategoryTree => _isLoadingCategoryTree;
  String? get categoryTreeError => _categoryTreeError;

  // Load products by category tree with complete details
  Future<void> loadProductsByCategoryTree(String slug,
      {bool refresh = true}) async {
    if (refresh) {
      _isLoadingCategoryTree = true;
      _categoryTreeError = null;
      _categoryTreeProducts = [];
      _categoryTreeSubcategories = [];
      notifyListeners();
    }

    try {
      final categoryService = CategoryService();
      print('Fetching products for category: $slug');
      final result = await categoryService.getProductsByCategoryTree(slug);

      if (result['success']) {
        // Store subcategories
        if (result.containsKey('subcategories')) {
          _categoryTreeSubcategories =
              List<CategoryModel>.from(result['subcategories']);
        }

        // Get basic product data
        final List<Map<String, dynamic>> basicProducts =
            List<Map<String, dynamic>>.from(result['basicProducts'] ?? []);
        print('Fetched ${basicProducts.length} basic products');

        if (basicProducts.isEmpty) {
          _isLoadingCategoryTree = false;
          notifyListeners();
          return;
        }

        // Fetch full details for each product
        List<ProductModel> completeProducts = [];

        // Use ProductService to fetch complete details
        final productService = ProductService();

        // Fetch each product's complete details
        for (var basicProduct in basicProducts) {
          try {
            final String slug = basicProduct['slug'];
            final detailResult = await productService.getProductBySlug(slug);

            if (detailResult['success'] && detailResult['data'] != null) {
              completeProducts.add(detailResult['data']);
            } else {
              // If can't get detailed info, create simple product from basic info
              final basicInfo = basicProduct['basicInfo'];
              completeProducts.add(ProductModel(
                id: basicInfo['id'] ?? 0,
                name: basicInfo['name'] ?? '',
                slug: basicInfo['slug'] ?? '',
                description: basicInfo['description'] ?? '',
                category: basicInfo['category']?.toString() ?? '',
                brand: BrandModel.empty(),
                regularPrice: basicInfo['regular_price']?.toString() ?? '0.00',
                salePrice: basicInfo['sale_price']?.toString() ?? '0.00',
                stockQuantity: basicInfo['stock_quantity'] ?? 0,
                isActive: basicInfo['is_active'] ?? false,
                isFeatured: basicInfo['is_featured'] ?? false,
                images: [],
                createdAt: basicInfo['created_at'] ?? '',
              ));
            }
          } catch (e) {
            print(
                'Error fetching details for product ${basicProduct['slug']}: $e');
            // Continue with next product
          }
        }

        _categoryTreeProducts = completeProducts;
        _isLoadingCategoryTree = false;
        notifyListeners();
      } else {
        print('Error fetching products: ${result['message']}');
        _categoryTreeError = result['message'];
        _isLoadingCategoryTree = false;
        notifyListeners();
      }
    } catch (e) {
      print('Exception in loadProductsByCategoryTree: $e');
      _categoryTreeError = e.toString();
      _isLoadingCategoryTree = false;
      notifyListeners();
    }
  }

  // Get all products or with specific parameters
  Future<void> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? ordering,
    bool refresh = true,
  }) async {
    if (refresh) {
      _isLoadingAllProducts = true;
      _allProductsError = null;
      _allProducts = [];
      notifyListeners();
    }

    try {
      final result = await _productService.getProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
        ordering: ordering,
      );

      if (result['success']) {
        if (refresh) {
          _allProducts = List<ProductModel>.from(result['data']);
        } else {
          _allProducts.addAll(List<ProductModel>.from(result['data']));
        }

        _isLoadingAllProducts = false;
        notifyListeners();
      } else {
        _allProductsError = result['message'];
        _isLoadingAllProducts = false;
        notifyListeners();
      }
    } catch (e) {
      _allProductsError = e.toString();
      _isLoadingAllProducts = false;
      notifyListeners();
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    _isLoadingFeatured = true;
    _featuredError = null;
    notifyListeners();

    try {
      final result = await _productService.getFeaturedProducts();

      if (result['success']) {
        _featuredProducts = List<ProductModel>.from(result['data']);
        _isLoadingFeatured = false;
        notifyListeners();
      } else {
        _featuredError = result['message'];
        _isLoadingFeatured = false;
        notifyListeners();
      }
    } catch (e) {
      _featuredError = e.toString();
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  // Load new arrivals
  Future<void> loadNewArrivals() async {
    _isLoadingNewArrivals = true;
    _newArrivalsError = null;
    notifyListeners();

    try {
      final result = await _productService.getNewArrivals();

      if (result['success']) {
        _newArrivals = List<ProductModel>.from(result['data']);
        _isLoadingNewArrivals = false;
        notifyListeners();
      } else {
        _newArrivalsError = result['message'];
        _isLoadingNewArrivals = false;
        notifyListeners();
      }
    } catch (e) {
      _newArrivalsError = e.toString();
      _isLoadingNewArrivals = false;
      notifyListeners();
    }
  }

  // Load best sellers
  Future<void> loadBestSellers() async {
    _isLoadingBestSellers = true;
    _bestSellersError = null;
    notifyListeners();

    try {
      final result = await _productService.getBestSellers();

      if (result['success']) {
        _bestSellers = List<ProductModel>.from(result['data']);
        _isLoadingBestSellers = false;
        notifyListeners();
      } else {
        _bestSellersError = result['message'];
        _isLoadingBestSellers = false;
        notifyListeners();
      }
    } catch (e) {
      _bestSellersError = e.toString();
      _isLoadingBestSellers = false;
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _isLoadingSearch = true;
    _searchError = null;
    notifyListeners();

    try {
      final result = await _productService.searchProducts(query);

      if (result['success']) {
        _searchResults = List<ProductModel>.from(result['data']);
        _isLoadingSearch = false;
        notifyListeners();
      } else {
        _searchError = result['message'];
        _isLoadingSearch = false;
        notifyListeners();
      }
    } catch (e) {
      _searchError = e.toString();
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  // Load products by category
  Future<void> loadProductsByCategory(String categorySlug,
      {bool refresh = true}) async {
    if (refresh) {
      _isLoadingCategory = true;
      _categoryError = null;
      _categoryProducts = [];
      _categoryNextPage = null;
      _categoryPreviousPage = null;
      notifyListeners();
    }

    try {
      final result = await _productService.getProductsByCategory(categorySlug);

      if (result['success']) {
        if (refresh) {
          _categoryProducts = List<ProductModel>.from(result['data']);
        } else {
          _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        }

        _categoryTotalCount = result['count'] ?? 0;
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
        _isLoadingCategory = false;
        notifyListeners();
      } else {
        _categoryError = result['message'];
        _isLoadingCategory = false;
        notifyListeners();
      }
    } catch (e) {
      _categoryError = e.toString();
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  // Load more products for a category (pagination)
  Future<void> loadMoreCategoryProducts(String categorySlug) async {
    if (_categoryNextPage == null || _isLoadingCategory) return;

    _isLoadingCategory = true;
    notifyListeners();

    // Extract page number from next page URL
    Uri nextPageUri = Uri.parse(_categoryNextPage!);
    String? pageStr = nextPageUri.queryParameters['page'];
    int page = int.tryParse(pageStr ?? '1') ?? 1;

    try {
      final result = await _productService.getProductsByCategory(
        categorySlug,
        page: page,
      );

      if (result['success']) {
        _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
        _isLoadingCategory = false;
        notifyListeners();
      } else {
        _categoryError = result['message'];
        _isLoadingCategory = false;
        notifyListeners();
      }
    } catch (e) {
      _categoryError = e.toString();
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  // Load product details
  Future<void> loadProductDetails(String slug) async {
    _isLoadingProductDetails = true;
    _productDetailsError = null;
    notifyListeners();

    try {
      final result = await _productService.getProductBySlug(slug);

      if (result['success']) {
        _selectedProduct = result['data'];
        _isLoadingProductDetails = false;
        notifyListeners();
      } else {
        _productDetailsError = result['message'];
        _isLoadingProductDetails = false;
        notifyListeners();
      }
    } catch (e) {
      _productDetailsError = e.toString();
      _isLoadingProductDetails = false;
      notifyListeners();
    }
  }

  // Convert product to map for product card
  List<Map<String, dynamic>> convertProductsToCardMaps(
      List<ProductModel> products) {
    return products.map((product) => product.toCardMap()).toList();
  }

  // Toggle wishlist status
  void toggleWishlist(ProductModel product) {
    // In a real app, this would call an API to add/remove from wishlist
    // For now, we'll just update the local state
    final updatedProduct =
        product.copyWith(isWishlisted: !product.isWishlisted);

    // Update product in all lists
    _updateProductInLists(updatedProduct);

    notifyListeners();

    // Here you would also make the API call to update the server
    developer.log(
        'Toggled wishlist for product: ${product.name}, new status: ${!product.isWishlisted}');
  }

  // Helper to update a product in all lists
  void _updateProductInLists(ProductModel updatedProduct) {
    // Update in featured products
    final featuredIndex =
        _featuredProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (featuredIndex >= 0) {
      _featuredProducts[featuredIndex] = updatedProduct;
    }

    // Update in new arrivals
    final newArrivalsIndex =
        _newArrivals.indexWhere((p) => p.id == updatedProduct.id);
    if (newArrivalsIndex >= 0) {
      _newArrivals[newArrivalsIndex] = updatedProduct;
    }

    // Update in best sellers
    final bestSellersIndex =
        _bestSellers.indexWhere((p) => p.id == updatedProduct.id);
    if (bestSellersIndex >= 0) {
      _bestSellers[bestSellersIndex] = updatedProduct;
    }

    // Update in category products
    final categoryIndex =
        _categoryProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (categoryIndex >= 0) {
      _categoryProducts[categoryIndex] = updatedProduct;
    }

    // Update in search results
    final searchIndex =
        _searchResults.indexWhere((p) => p.id == updatedProduct.id);
    if (searchIndex >= 0) {
      _searchResults[searchIndex] = updatedProduct;
    }

    // Update in all products
    final allProductsIndex =
        _allProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (allProductsIndex >= 0) {
      _allProducts[allProductsIndex] = updatedProduct;
    }

    // Update selected product if it's the same
    if (_selectedProduct != null && _selectedProduct!.id == updatedProduct.id) {
      _selectedProduct = updatedProduct;
    }
  }

  // Clear errors
  void clearErrors() {
    _featuredError = null;
    _newArrivalsError = null;
    _bestSellersError = null;
    _searchError = null;
    _categoryError = null;
    _allProductsError = null;
    _productDetailsError = null;
    notifyListeners();
  }
}
