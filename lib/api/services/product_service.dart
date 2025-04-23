// lib/api/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/product_model.dart';

class ProductService {
  final String baseUrl = 'http://65.1.88.148:8000/api/v1';

  // Fetch all products with optional parameters
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
    String? ordering,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional parameters if provided
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final uri = Uri.parse('$baseUrl/products/products/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert results to ProductModel list
        final List<dynamic> results = data['results'];
        final products =
            results.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': products,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching products: $e',
      };
    }
  }

  // Get new arrivals - most recently created products
  Future<Map<String, dynamic>> getNewArrivals({int limit = 10}) async {
    return getProducts(ordering: '-created_at', limit: limit);
  }

  // Get best sellers - products with highest order count
  Future<Map<String, dynamic>> getBestSellers({int limit = 10}) async {
    return getProducts(ordering: '-order_count', limit: limit);
  }

  // Get featured products
  Future<Map<String, dynamic>> getFeaturedProducts({int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/products/').replace(
          queryParameters: {'is_featured': 'true', 'limit': limit.toString()});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert results to ProductModel list
        final List<dynamic> results = data['results'];
        final products =
            results.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': products,
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load featured products: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching featured products: $e',
      };
    }
  }

  // Get single product details by slug
  Future<Map<String, dynamic>> getProductBySlug(String slug) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/products/products/$slug/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': ProductModel.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load product details: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching product details: $e',
      };
    }
  }

  // Get products by category
  Future<Map<String, dynamic>> getProductsByCategory(String categorySlug,
      {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/products/').replace(
          queryParameters: {
            'category': categorySlug,
            'page': page.toString(),
            'limit': limit.toString()
          });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert results to ProductModel list
        final List<dynamic> results = data['results'];
        final products =
            results.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': products,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching products: $e',
      };
    }
  }

  // Search products
  Future<Map<String, dynamic>> searchProducts(String query,
      {int page = 1, int limit = 20}) async {
    return getProducts(search: query, page: page, limit: limit);
  }
}
