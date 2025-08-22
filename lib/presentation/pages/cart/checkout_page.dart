// lib/presentation/pages/cart/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // Add this dependency to pubspec.yaml
import '../../../providers/cart_provider.dart';
import '../../../api/services/order_service.dart';
import '../../../core/models/order_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();

  // Razorpay integration
  late Razorpay _razorpay;

  bool _isLoading = false;
  bool _processingPayment = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _paymentMethod = 'COD';
  List<Map<String, dynamic>>? _createdOrders;
  int? _currentOrderId; // Store current order ID for payment verification

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _razorpay.clear(); // Clear Razorpay listeners
    super.dispose();
  }

  // Razorpay Event Handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');

    if (!mounted) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      // Verify payment with backend
      final verificationResult = await _orderService.verifyPayment(
        orderId: _currentOrderId!,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;

      if (verificationResult['success']) {
        // Payment verified successfully
        _showSuccessDialog(
          'Payment successful! Your order has been confirmed.\n\nPayment ID: ${response.paymentId}',
        );
      } else {
        _showError('Payment verification failed. Please contact support.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Payment verification error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');

    if (!mounted) return;

    setState(() {
      _processingPayment = false;
    });

    // Handle different error scenarios
    String errorMessage = 'Payment failed';

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment was cancelled';
    } else if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage =
          'Network error. Please check your internet connection and try again.';
    } else if (response.message != null) {
      errorMessage = 'Payment failed: ${response.message}';
    }

    _showError(errorMessage);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');

    if (!mounted) return;

    setState(() {
      _processingPayment = false;
    });

    _showError('External wallet payment not supported currently');
  }

  Future<void> _checkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare shipping address
      final shippingAddress = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'street': _streetController.text.trim(),
        'area': _areaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': 'India',
        'pincode': _pincodeController.text.trim(),
        'use_for_billing': true,
      };

      print('Checkout payload: $shippingAddress');
      print('Payment method: $_paymentMethod');

      // For COD orders, proceed with checkout immediately
      if (_paymentMethod == 'COD') {
        await _processCODOrder(shippingAddress);
      } else {
        // For online payments, first create order then initiate payment
        await _processOnlinePaymentOrder(shippingAddress);
      }
    } catch (e) {
      print('Checkout exception: $e');
      if (mounted) {
        _showError('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processCODOrder(Map<String, dynamic> shippingAddress) async {
    // For COD, complete the checkout process with auto shipment creation
    final checkoutResult = await _orderService.checkout(
      shippingAddress: shippingAddress,
      paymentMethod: _paymentMethod,
      clearCart: true,
      autoCreateShipments: true,
    );

    print('COD Checkout result: $checkoutResult');

    if (!mounted) return;

    if (checkoutResult['success']) {
      final data = checkoutResult['data'];
      List<dynamic> ordersData = data['orders'] ?? [];

      if (ordersData.isNotEmpty) {
        // Store raw order data
        final orders = ordersData.cast<Map<String, dynamic>>();

        if (mounted) {
          setState(() {
            _createdOrders = orders;
          });

          // Check shipment results
          String successMessage =
              'Order placed successfully! You can pay cash on delivery.';

          if (data['shipment_results'] != null) {
            final shipmentResults = data['shipment_results'] as List<dynamic>;
            final failedShipments =
                shipmentResults.where((s) => s['success'] == false);
            final successfulShipments =
                shipmentResults.where((s) => s['success'] == true).length;

            if (successfulShipments > 0) {
              successMessage +=
                  '\n\nShipping has been automatically set up for your orders.';
            } else if (failedShipments.isNotEmpty) {
              successMessage +=
                  '\n\nNote: Shipping will be set up manually by the seller.';
              print('Shipping setup failed: ${failedShipments.first['error']}');
            }
          }

          _showSuccessDialog(successMessage);
        }
      } else {
        if (mounted) {
          _showError('No orders were created');
        }
      }
    } else {
      if (mounted) {
        _showError(checkoutResult['message'] ?? 'Order creation failed');
      }
    }
  }

  Future<void> _processOnlinePaymentOrder(
      Map<String, dynamic> shippingAddress) async {
    if (!mounted) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      // First create the order without clearing cart
      final checkoutResult = await _orderService.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        clearCart: false, // Don't clear cart yet - wait for payment success
        autoCreateShipments:
            false, // Don't create shipments until payment is confirmed
      );

      if (!mounted) return;

      if (checkoutResult['success']) {
        final data = checkoutResult['data'];
        List<dynamic> ordersData = data['orders'] ?? [];

        if (ordersData.isNotEmpty) {
          final orders = ordersData.cast<Map<String, dynamic>>();
          final firstOrder = orders.first;

          // Extract order ID safely
          final orderId = _extractOrderId(firstOrder);
          if (orderId == null) {
            _showError('Invalid order data received');
            return;
          }

          setState(() {
            _createdOrders = orders;
            _currentOrderId = orderId;
          });

          // Now initiate payment
          await _initiateRazorpayPayment(orderId);
        } else {
          _showError('Failed to create order');
        }
      } else {
        _showError(checkoutResult['message'] ?? 'Order creation failed');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating order: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
      }
    }
  }

  // Helper method to safely extract order ID
  int? _extractOrderId(Map<String, dynamic> orderData) {
    try {
      if (orderData['order_id'] != null) {
        return int.parse(orderData['order_id'].toString());
      }
      if (orderData['id'] != null) {
        return int.parse(orderData['id'].toString());
      }
      return null;
    } catch (e) {
      print('Error extracting order ID: $e');
      return null;
    }
  }

  Future<void> _initiateRazorpayPayment(int orderId) async {
    if (!mounted) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      // Initiate Razorpay payment
      final paymentResult = await _orderService.initiatePayment(
        orderId: orderId,
      );

      if (!mounted) return;

      if (paymentResult['success']) {
        final paymentData = paymentResult['data'];

        // Launch Razorpay payment
        await _launchRazorpayPayment(paymentData);
      } else {
        setState(() {
          _processingPayment = false;
        });
        _showError(paymentResult['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
        _showError('Payment error: $e');
      }
    }
  }

  Future<void> _launchRazorpayPayment(Map<String, dynamic> paymentData) async {
    try {
      final amount = paymentData['amount']; // Amount in paise
      final currency = paymentData['currency'] ?? 'INR';
      final razorpayOrderId = paymentData['order_id'];
      final keyId = paymentData['key_id'];

      var options = {
        'key': keyId,
        'amount': amount,
        'currency': currency,
        'name': paymentData['name'] ?? 'Anugami Store',
        'description': paymentData['description'] ?? 'Payment for your order',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
        },
        'theme': {'color': '#FF7A2E'},
        'notes': {
          'order_id': _currentOrderId.toString(),
        },
        // Remove the modal callback - it's not supported
      };

      print('Launching Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
        _showError('Payment launch error: $e');
      }
    }
  }

  Future<void> _clearCartAndNavigate() async {
    try {
      // Clear the cart first
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.clearCart();
        print('Cart cleared successfully');
      }

      // Small delay to ensure cart clearing completes
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to orders page
      if (mounted) {
        print('Navigating to orders page');
        context.go('/orders');
      }
    } catch (e) {
      print('Error clearing cart and navigating: $e');
      // Still try to navigate even if cart clearing fails
      if (mounted) {
        try {
          context.go('/orders');
        } catch (navError) {
          print('Navigation error: $navError');
          // Fallback: pop current page
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showError(String message) {
    // Check if widget is still mounted and context is valid
    if (!mounted) {
      print('Widget not mounted, logging error: $message');
      return;
    }

    // Use addPostFrameCallback to ensure widget tree is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        print('Widget disposed before showing error: $message');
        return;
      }

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        // If SnackBar fails, just print the error
        print('Failed to show error SnackBar: $e');
        print('Original error: $message');
      }
    });
  }

  // Show success dialog instead of SnackBar to avoid widget lifecycle issues
  void _showSuccessDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text(
          'Order Placed Successfully!',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _clearCartAndNavigate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A2E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF7A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),
                        const SizedBox(height: 16),
                        _buildShippingAddressSection(),
                        const SizedBox(height: 16),
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
          if (_isLoading || _processingPayment)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF7A2E)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _processingPayment
                          ? 'Processing Payment...'
                          : 'Creating Order...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFFFF7A2E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items (${cartProvider.totalQuantity})',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '₹${cartProvider.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shipping',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      cartProvider.shippingCost == 0
                          ? 'FREE'
                          : '₹${cartProvider.shippingCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: cartProvider.shippingCost == 0
                            ? Colors.green
                            : Colors.black,
                        fontWeight: cartProvider.shippingCost == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (cartProvider.taxAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tax',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '₹${cartProvider.taxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${cartProvider.finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A2E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShippingAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFFF7A2E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length < 10) {
                        return 'Please enter valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address *',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.home_outlined),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area/Locality *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter area';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter pincode';
                      }
                      if (value.trim().length != 6) {
                        return 'Please enter valid pincode';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payment_outlined,
                  color: Color(0xFFFF7A2E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.money, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        const Text('Cash on Delivery (COD)'),
                      ],
                    ),
                    subtitle: const Text('Pay when your order is delivered'),
                    value: 'COD',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFFFF7A2E),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Image.network(
                          'https://razorpay.com/assets/razorpay-glyph.svg',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.credit_card,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Pay Online'),
                      ],
                    ),
                    subtitle: const Text('UPI, Cards, Net Banking, Wallets'),
                    value: 'Razorpay-UPI',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFFFF7A2E),
                  ),
                ],
              ),
            ),
            if (_paymentMethod != 'COD') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your payment is secure and encrypted',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${cartProvider.finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || _processingPayment ? null : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading || _processingPayment
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _processingPayment
                                  ? 'Processing Payment...'
                                  : 'Creating Order...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _paymentMethod == 'COD'
                                  ? Icons.shopping_bag
                                  : Icons.payment,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _paymentMethod == 'COD'
                                  ? 'Place Order'
                                  : 'Proceed to Payment',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_paymentMethod != 'COD') ...[
                const SizedBox(height: 8),
                const Text(
                  'You will be redirected to secure payment gateway',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
