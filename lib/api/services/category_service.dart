// lib/api/services/category_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/category_model.dart';

class CategoryService {
  final String baseUrl = 'http://65.1.88.148:8000/api/v1/categories';

  // Fetch flat list of categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Fetch hierarchical tree structure of categories
  Future<List<CategoryModel>> getCategoryTree() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/tree/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((item) => CategoryModel.fromTreeJson(item)).toList();
      } else {
        throw Exception('Failed to load category tree: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category tree: $e');
    }
  }
}
