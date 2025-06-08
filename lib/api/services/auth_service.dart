// lib/api/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://3.6.174.34:8000/api/v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      print(responseData);

      if (response.statusCode == 200) {
        // Login successful
        if (responseData['token'] != null) {
          // Save the token for future authenticated requests
          await _saveToken(responseData['token']);

          // Save user data from login response
          final userData = {
            'id': responseData['customer_id'] ?? '',
            'email': responseData['email'] ?? '',
            'full_name': responseData['full_name'] ?? '',
          };

          await _saveUserData(userData);
          await _secureStorage.write(key: 'user_password', value: password);
        }
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Login failed
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Login failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        print(responseData);
        // Registration successful
        if (responseData['token'] != null) {
          // Save the token for future authenticated requests
          await _saveToken(responseData['token']);

          // Save user data from registration response
          final userData = {
            'id': responseData['id'] ?? '',
            'email': responseData['email'] ?? '',
            'full_name': responseData['full_name'] ?? '',
          };

          await _saveUserData(userData);
        }
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Registration failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Add a new address for the customer
  Future<Map<String, dynamic>> addAddress(
      Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        print('inside this token');
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Make sure we have all required fields
      if (!addressData.containsKey('phone')) {
        addressData['phone'] = ''; // Add a default empty phone if not provided
      }

      // Add country if missing (seems required by your API)
      if (!addressData.containsKey('country')) {
        addressData['country'] = 'India'; // Default country
      }

      final response = await http.post(
        Uri.parse('$baseUrl/customers/addresses/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(addressData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Address added successfully
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Failed to add address
        print('Address creation failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add address',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Exception in addAddress: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Save auth token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save user data
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Get saved password (from secure storage)
  Future<String?> getSavedPassword() async {
    return await _secureStorage.read(key: 'user_password');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await _secureStorage.delete(key: 'user_password');
  }
}
