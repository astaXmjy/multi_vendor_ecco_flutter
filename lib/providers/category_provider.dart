// lib/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import '../api/services/category_service.dart';
import '../core/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  List<CategoryModel> _categoryTree = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get categoryTree => _categoryTree;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize by loading categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load category tree structure
  Future<void> loadCategoryTree() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryTree = await _categoryService.getCategoryTree();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all root categories (level 0)
  List<CategoryModel> getRootCategories() {
    return _categories.where((category) => category.parentId == null).toList();
  }

  // Get subcategories of a parent
  List<CategoryModel> getSubcategories(String parentId) {
    return _categories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  // Get featured categories
  List<CategoryModel> getFeaturedCategories() {
    return _categories.where((category) => category.isFeatured).toList();
  }

  // Clear state
  void clear() {
    _categories = [];
    _categoryTree = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
