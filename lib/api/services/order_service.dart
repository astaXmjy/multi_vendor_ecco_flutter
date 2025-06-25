import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderService {
  final String baseUrl = 'http://3.6.174.34:8000/api/v1/orders';

  // Checkout - Create orders from cart items
  Future<Map<String, dynamic>> checkout({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    bool clearCart = true,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final payload = {
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'clear_cart': clearCart,
      };

      print('Making checkout request to: $baseUrl/orders/checkout/');
      print('Payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/orders/checkout/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Checkout Response Status: ${response.statusCode}');
      print('Checkout Response Headers: ${response.headers}');
      print('Checkout Response Body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') == true) {
        return {
          'success': false,
          'message':
              'Server returned HTML error page. Status: ${response.statusCode}',
          'error_details': 'Check server logs for detailed error information',
        };
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid JSON response from server',
          'error_details': 'Response: ${response.body.substring(0, 200)}...',
        };
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Checkout failed',
          'errors': responseData,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Checkout Exception: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Initiate payment for an order
  Future<Map<String, dynamic>> initiatePayment({
    required int orderId,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final payload = <String, dynamic>{};
      if (callbackUrl != null) payload['callback_url'] = callbackUrl;
      if (redirectUrl != null) payload['redirect_url'] = redirectUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/initiate-payment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Payment Initiation Response Status: ${response.statusCode}');
      print('Payment Initiation Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['error'] ?? 'Payment initiation failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Payment Initiation Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/check-payment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Payment Status Response Status: ${response.statusCode}');
      print('Payment Status Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to check payment status',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Payment Status Check Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get user's orders
  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/my_orders/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch orders',
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

  // Track order shipment
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      print(orderId);

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/track/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Track Order Response Status: ${response.statusCode}');
      print('Track Order Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to track order',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Track Order Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
