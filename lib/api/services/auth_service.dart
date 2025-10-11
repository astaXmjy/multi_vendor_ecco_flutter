// lib/api/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://anugami.com/api/v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Register a new user (now with email OTP)
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
      print('Registration response: $responseData');

      if (response.statusCode == 201) {
        // Registration successful - OTP sent to email
        return {
          'success': true,
          'message': responseData['message'] ??
              'Registration successful. Please check your email for verification code.',
          'email': responseData['email'],
          'requires_verification':
              responseData['requires_verification'] ?? true,
          'data': responseData,
        };
      } else {
        // Registration failed
        return {
          'success': false,
          'message': responseData['error'] ??
              responseData['message'] ??
              'Registration failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Request OTP for email verification
  Future<Map<String, dynamic>> requestOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/request-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      print('Request OTP response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'OTP sent successfully to your email',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('Request OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Verify OTP and activate account
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/verify-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final responseData = json.decode(response.body);
      print('Verify OTP response: $responseData');

      if (response.statusCode == 200) {
        // OTP verification successful - account activated and logged in
        if (responseData['token'] != null) {
          // Save the token for future authenticated requests
          await _saveToken(responseData['token']);

          // Save user data from verification response
          final userData = {
            'id': responseData['customer_id'] ?? '',
            'email': responseData['email'] ?? '',
            'full_name': responseData['full_name'] ?? '',
          };

          await _saveUserData(userData);
        }

        return {
          'success': true,
          'message': responseData['message'] ??
              'Email verified successfully! Account activated.',
          'token': responseData['token'],
          'customer_id': responseData['customer_id'],
          'email': responseData['email'],
          'full_name': responseData['full_name'],
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'OTP verification failed',
          'remaining_attempts': responseData['remaining_attempts'],
        };
      }
    } catch (e) {
      print('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/resend-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      print('Resend OTP response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ??
              'New OTP sent successfully to your email',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      print('Resend OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Login user (now with email verification check)
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
      print('Login response: $responseData');

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
          'token': responseData['token'],
          'customer_id': responseData['customer_id'],
          'email': responseData['email'],
          'full_name': responseData['full_name'],
        };
      } else if (response.statusCode == 403 &&
          responseData['requires_verification'] == true) {
        // Email not verified
        return {
          'success': false,
          'message': responseData['message'] ??
              'Please verify your email before logging in',
          'error': responseData['error'] ?? 'Email not verified',
          'requires_verification': true,
          'email': responseData['email'] ?? email,
        };
      } else {
        // Login failed
        return {
          'success': false,
          'message': responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Login failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _getToken();

      if (token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/customers/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        print('Logout response: ${response.body}');
      }

      // Clear local storage regardless of API response
      await _clearUserData();

      return {
        'success': true,
        'message': 'Successfully logged out',
      };
    } catch (e) {
      // Clear local data even if error occurs
      await _clearUserData();
      print('Logout error: $e');
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Add a new address for the customer
  Future<Map<String, dynamic>> addAddress(
      Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        print('No auth token found');
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
          'message': responseData['message'] ??
              responseData['error'] ??
              'Failed to add address',
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

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
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

  // Get authorization headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
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

  // Clear all user data
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await _secureStorage.delete(key: 'user_password');
  }
}
