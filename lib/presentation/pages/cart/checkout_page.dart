import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/cart_provider.dart';
import '../../../api/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../widgets/payment_tracking_dialog.dart';
import '../shared/custom_app_bar.dart';

// Add this import for debugging
import '../../../api/services/debug_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final DebugService _debugService = DebugService(); // Add debug service

  bool _isLoading = false;
  bool _processingPayment = false;
  bool _debugMode = false; // Add debug mode flag

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
  List<OrderModel>? _createdOrders;

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
    super.dispose();
  }

  Future<void> _checkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

      // Call checkout API
      final checkoutResult = await _orderService.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        clearCart: true,
      );

      print('Checkout result: $checkoutResult');

      if (!mounted) return;

      if (checkoutResult['success']) {
        final data = checkoutResult['data'];
        final orders = (data['orders'] as List<dynamic>)
            .map((order) => OrderModel.fromJson(order))
            .toList();

        setState(() {
          _createdOrders = orders;
        });

        // Show success message
        _showSuccessMessage('${orders.length} order(s) created successfully!');

        // If payment method is not COD, initiate payment
        if (_paymentMethod != 'COD' && orders.isNotEmpty) {
          await _initiatePayment(orders.first.id);
        } else {
          // Clear cart and navigate
          await _clearCartAndNavigate();
        }
      } else {
        _showError(checkoutResult['message'] ?? 'Checkout failed');
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

  Future<void> _initiatePayment(int orderId) async {
    setState(() {
      _processingPayment = true;
    });

    try {
      final paymentResult = await _orderService.initiatePayment(
        orderId: orderId,
        callbackUrl: 'https://yourapp.com/payment/callback',
        redirectUrl: 'https://yourapp.com/payment/success',
      );

      if (paymentResult['success']) {
        final paymentUrl = paymentResult['data']['payment_url'];
        final transactionId = paymentResult['data']['transaction_id'];

        if (paymentUrl != null) {
          // Launch payment URL
          await _launchPaymentUrl(paymentUrl, orderId, transactionId);
        } else {
          _showError('Payment URL not received');
        }
      } else {
        _showError(paymentResult['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      _showError('Payment error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
      }
    }
  }

  Future<void> _launchPaymentUrl(
      String paymentUrl, int orderId, String transactionId) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Start payment status checking
        _startPaymentStatusCheck(orderId, transactionId);
      } else {
        _showError('Cannot open payment page');
      }
    } catch (e) {
      _showError('Error opening payment page: $e');
    }
  }

  void _startPaymentStatusCheck(int orderId, String transactionId) {
    // Show payment tracking dialog
    _showPaymentTrackingDialog(orderId, transactionId);
  }

  void _showPaymentTrackingDialog(int orderId, String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentTrackingDialog(
        orderId: orderId,
        transactionId: transactionId,
        orderService: _orderService,
        onPaymentComplete: (bool success) {
          Navigator.of(context).pop();
          if (success) {
            _clearCartAndNavigate();
          }
        },
      ),
    );
  }

  Future<void> _clearCartAndNavigate() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCartItems();

    if (mounted) {
      context.go('/orders');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          // Debug toggle button
          IconButton(
            icon:
                Icon(_debugMode ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _debugMode = !_debugMode;
              });
            },
          ),
        ],
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Debug section
                        if (_debugMode) ...[
                          Card(
                            color: Colors.yellow[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Debug Tools',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _runDebugTests,
                                    child: const Text('Test Auth & Cart'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Cart Summary
                        _buildCartSummary(cartProvider),
                        const SizedBox(height: 24),

                        // Shipping Information
                        _buildShippingForm(),
                        const SizedBox(height: 24),

                        // Payment Method
                        _buildPaymentMethodSelection(),
                        const SizedBox(height: 32),

                        // Place Order Button
                        _buildCheckoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Add debug methods
  Future<void> _runDebugTests() async {
    setState(() {
      _isLoading = true;
    });

    // Test auth
    final authResult = await _debugService.testAuth();
    print('Auth Test Result: $authResult');

    if (mounted) {
      _showSuccessMessage('Auth: ${authResult['success'] ? 'OK' : 'FAILED'}');
    }

    // Test cart
    final cartResult = await _debugService.testCart();
    print('Cart Test Result: $cartResult');

    if (mounted) {
      _showSuccessMessage('Cart: ${cartResult['success'] ? 'OK' : 'FAILED'}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items (${cartProvider.itemCount})'),
                Text('₹${cartProvider.subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping'),
                Text(cartProvider.shippingCost > 0
                    ? '₹${cartProvider.shippingCost.toStringAsFixed(0)}'
                    : 'FREE'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${cartProvider.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
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
  }

  Widget _buildShippingForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
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
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 10) {
                        return 'Invalid phone';
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
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your street address';
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
                      labelText: 'Area *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      border: OutlineInputBorder(),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 6) {
                    return 'Invalid pincode';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.money, color: Color(0xFFFF7A2E)),
                  SizedBox(width: 12),
                  Text('Cash on Delivery'),
                ],
              ),
              value: 'COD',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              activeColor: const Color(0xFFFF7A2E),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Color(0xFFFF7A2E)),
                  SizedBox(width: 12),
                  Text('PhonePe UPI'),
                ],
              ),
              value: 'PhonePe-UPI',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              activeColor: const Color(0xFFFF7A2E),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFFFF7A2E)),
                  SizedBox(width: 12),
                  Text('PhonePe Card'),
                ],
              ),
              value: 'PhonePe-Card',
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
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _processingPayment) ? null : _checkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A2E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: (_isLoading || _processingPayment)
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                _paymentMethod == 'COD' ? 'PLACE ORDER' : 'PROCEED TO PAYMENT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
