// lib/api/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderService {
  final String baseUrl = 'https://anugami.com/api/v1/orders';

  // Checkout - Create orders from cart items
  Future<Map<String, dynamic>> checkout({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    bool clearCart = true,
    bool autoCreateShipments = false, // Add option for auto shipment creation
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
        'auto_create_shipments': autoCreateShipments, // Pass to backend
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
          'message': responseData['error'] ??
              responseData['message'] ??
              'Checkout failed',
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

  // Initiate payment for an order (Razorpay integration)
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

      // Prepare payload - Django expects this structure
      final payload = <String, dynamic>{};
      if (callbackUrl != null) payload['callback_url'] = callbackUrl;
      if (redirectUrl != null) payload['redirect_url'] = redirectUrl;

      // Fix the URL structure - remove double "orders"
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/initiate-payment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print(
          'Payment Initiation URL: $baseUrl/orders/$orderId/initiate-payment/');
      print('Payment Initiation Payload: ${json.encode(payload)}');
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

  // Verify payment after completion (Razorpay)
  Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
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
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/verify-payment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Payment Verification Response Status: ${response.statusCode}');
      print('Payment Verification Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Payment verification failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Payment Verification Error: $e');
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

  // Create shipment (Shipmojo integration)
  Future<Map<String, dynamic>> createShipment({
    required int orderId,
    double? weight,
    double? length,
    double? width,
    double? height,
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
      if (weight != null) payload['weight'] = weight;
      if (length != null) payload['length'] = length;
      if (width != null) payload['width'] = width;
      if (height != null) payload['height'] = height;

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/create-shipment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Create Shipment Response Status: ${response.statusCode}');
      print('Create Shipment Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to create shipment',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Create Shipment Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Auto assign courier (Shipmojo)
  Future<Map<String, dynamic>> autoAssignCourier(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/auto-assign-courier/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('Auto Assign Courier Response Status: ${response.statusCode}');
      print('Auto Assign Courier Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to auto assign courier',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Auto Assign Courier Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Schedule pickup (Shipmojo)
  Future<Map<String, dynamic>> schedulePickup(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/schedule-pickup/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('Schedule Pickup Response Status: ${response.statusCode}');
      print('Schedule Pickup Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to schedule pickup',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Schedule Pickup Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Track order shipment (Shipmojo integration)
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

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

  // Check serviceability (Shipmojo)
  Future<Map<String, dynamic>> checkServiceability(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/check-serviceability/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Check Serviceability Response Status: ${response.statusCode}');
      print('Check Serviceability Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to check serviceability',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Check Serviceability Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get shipping rates (Shipmojo)
  Future<Map<String, dynamic>> getShippingRates(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/get-shipping-rates/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Get Shipping Rates Response Status: ${response.statusCode}');
      print('Get Shipping Rates Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to get shipping rates',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Get Shipping Rates Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Generate shipping label (Shipmojo)
  Future<Map<String, dynamic>> generateLabel(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/generate-label/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('Generate Label Response Status: ${response.statusCode}');
      print('Generate Label Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to generate label',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Generate Label Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Cancel shipment (Shipmojo)
  Future<Map<String, dynamic>> cancelShipment(int orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel-shipment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('Cancel Shipment Response Status: ${response.statusCode}');
      print('Cancel Shipment Response Body: ${response.body}');

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
          'message': responseData['error'] ?? 'Failed to cancel shipment',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Cancel Shipment Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Complete shipping workflow for order (convenience method)
  Future<Map<String, dynamic>> completeShippingWorkflow({
    required int orderId,
    double? weight,
    double? length,
    double? width,
    double? height,
  }) async {
    try {
      // Step 1: Create shipment
      final createResult = await createShipment(
        orderId: orderId,
        weight: weight,
        length: length,
        width: width,
        height: height,
      );

      if (!createResult['success']) {
        return createResult;
      }

      // Step 2: Auto assign courier
      final assignResult = await autoAssignCourier(orderId);
      if (!assignResult['success']) {
        return assignResult;
      }

      // Step 3: Schedule pickup
      final pickupResult = await schedulePickup(orderId);
      if (!pickupResult['success']) {
        return pickupResult;
      }

      return {
        'success': true,
        'message': 'Shipping workflow completed successfully',
        'data': {
          'shipment': createResult['data'],
          'courier': assignResult['data'],
          'pickup': pickupResult['data'],
        },
      };
    } catch (e) {
      print('Complete Shipping Workflow Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
