// lib/api/services/profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../../core/models/profile_model.dart';

class ProfileService {
  final String baseUrl = 'http://3.6.174.34:8000/api/v1';

  // Get user profile
// In your ProfileService class
  // lib/api/services/profile_service.dart
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getToken();
      print("Auth token: ${token != null ? 'Found' : 'Not found'}");

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      print("Sending request to $baseUrl/customers/profile/");
      final response = await http.get(
        Uri.parse('$baseUrl/customers/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print("API response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print("Response successfully decoded as JSON");

          return {
            'success': true,
            'data': responseData,
          };
        } catch (e) {
          print("JSON decode error: $e");
          print("Response body: ${response.body}");
          return {
            'success': false,
            'message': 'Failed to parse response: $e',
          };
        }
      } else {
        print("Error response: ${response.body}");
        Map<String, dynamic> responseData = {};

        try {
          responseData = json.decode(response.body);
        } catch (_) {
          // Ignore JSON decode errors for error responses
        }

        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Failed to load profile (Status ${response.statusCode})',
          'errors': responseData,
        };
      }
    } catch (e, stackTrace) {
      print("Exception in getUserProfile: $e");
      print("Stack trace: $stackTrace");
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // lib/api/services/profile_service.dart - Add this method to your existing service
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/customers/profile/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(profileData),
      );

      final responseData = json.decode(response.body);
      print(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Failed to update profile',
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

  // Add this method to your ProfileService class
  Future<Map<String, dynamic>> updateUserProfileWithImage(
      Map<String, dynamic> profileData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Check if we have an image to upload
      final hasImageFile = profileData.containsKey('profile_picture') &&
          profileData['profile_picture'] is File;

      if (hasImageFile) {
        // Use multipart request for image upload
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/customers/profile/update/'),
        );

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Token $token',
        });

        // Add all other fields
        profileData.forEach((key, value) {
          if (key != 'profile_picture' && value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add the image file
        final File imageFile = profileData['profile_picture'];
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'profile_picture',
          fileStream,
          fileLength,
          filename: path.basename(imageFile.path),
          contentType: MediaType(
              'image', path.extension(imageFile.path).replaceAll('.', '')),
        );

        request.files.add(multipartFile);

        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        // Handle the response
        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': json.decode(response.body),
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to update profile: ${response.statusCode}',
            'errors': json.decode(response.body),
          };
        }
      } else {
        // No image file, use regular PUT request
        final response = await http.put(
          Uri.parse('$baseUrl/customers/profile/update/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: json.encode(profileData),
        );

        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ??
                responseData['detail'] ??
                'Failed to update profile',
            'errors': responseData,
          };
        }
      }
    } catch (e) {
      print("Error in updateUserProfileWithImage: $e");
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get saved auth token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
