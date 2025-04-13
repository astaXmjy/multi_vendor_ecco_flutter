// lib/api/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://65.1.88.148:8000/api/v1';

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

      if (response.statusCode == 200) {
        // Login successful
        if (responseData['token'] != null) {
          // Save the token for future authenticated requests
          await _saveToken(responseData['token']);

          // If the response includes user data, save it
          if (responseData['user'] != null) {
            await _saveUserData(responseData['user']);
          }
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
        // Registration successful
        if (responseData['token'] != null) {
          // Save the token for future authenticated requests
          await _saveToken(responseData['token']);

          // If the response includes user data, save it
          if (responseData['user'] != null) {
            await _saveUserData(responseData['user']);
          }
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
        return {
          'success': false,
          'message': 'Not authenticated',
        };
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

      if (response.statusCode == 201) {
        // Address added successfully
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Failed to add address
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add address',
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
  }
}
