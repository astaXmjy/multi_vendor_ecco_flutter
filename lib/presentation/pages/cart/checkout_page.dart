// lib/presentation/pages/cart/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../api/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/address_model.dart';

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
  bool _useExistingAddress = false;
  AddressModel? _selectedAddress;

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

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadAddresses();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _loadAddresses() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider =
          Provider.of<AddressProvider>(context, listen: false);
      addressProvider.loadAddresses().then((_) {
        if (addressProvider.defaultAddress != null) {
          setState(() {
            _selectedAddress = addressProvider.defaultAddress;
            _useExistingAddress = true;
          });
          _populateFormFromAddress(addressProvider.defaultAddress!);
        }
      });
    });
  }

  void _populateFormFromAddress(AddressModel address) {
    _nameController.text = address.fullName;
    _phoneController.text = address.phone;
    _streetController.text = address.street;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    // For other fields like area, landmark, email - you may need to parse them from street address
    // or have them as separate fields in your AddressModel
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
    _razorpay.clear();
    super.dispose();
  }

  // Razorpay Event Handlers - Updated for bulk payment verification
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');

    if (!mounted) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      // Updated verification call - no longer needs order ID
      final verificationResult = await _orderService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;

      if (verificationResult['success']) {
        final data = verificationResult['data'];
        final orders = data['orders'] ?? [];
        final totalOrders = data['total_orders'] ?? 0;

        _showSuccessDialog(
          'Payment successful! $totalOrders orders have been confirmed.\n\nPayment ID: ${response.paymentId}',
          isBulkPayment: true,
          orders: orders,
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

      // Single checkout call that handles both order creation and payment initiation
      final checkoutResult = await _orderService.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        clearCart: _paymentMethod == 'COD', // Clear cart immediately for COD
        autoCreateShipments:
            _paymentMethod == 'COD', // Auto-create shipments for COD
        callbackUrl: 'https://anugami.com/payment/callback/',
        redirectUrl: 'https://anugami.com/payment/success/',
      );

      print('Checkout result: $checkoutResult');

      if (!mounted) return;

      if (checkoutResult['success']) {
        final data = checkoutResult['data'];

        // Check if payment is required
        if (data['payment_required'] == true) {
          // Extract payment data and start Razorpay
          final razorpayData = data['razorpay_data'];
          await _startRazorpayPayment(razorpayData, data['orders']);
        } else {
          // COD order - show success immediately
          final orders = data['orders'] ?? [];
          _handleCODSuccess(data, orders);
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

  Future<void> _startRazorpayPayment(
    Map<String, dynamic> razorpayData,
    List<dynamic> orders,
  ) async {
    if (!mounted) return;

    setState(() {
      _processingPayment = true;
      _createdOrders = orders.cast<Map<String, dynamic>>();
    });

    try {
      var options = {
        'key': razorpayData['key_id'],
        'amount': razorpayData['amount'],
        'currency': razorpayData['currency'],
        'name': razorpayData['name'] ?? 'Anugami Store',
        'description': razorpayData['description'] ?? 'Payment for your orders',
        'order_id': razorpayData['order_id'],
        'prefill': razorpayData['prefill'] ??
            {
              'contact': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'name': _nameController.text.trim(),
            },
        'notes': razorpayData['notes'] ?? {},
        'theme': razorpayData['theme'] ?? {'color': '#FF7A2E'},
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

  void _handleCODSuccess(Map<String, dynamic> data, List<dynamic> orders) {
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

    _showSuccessDialog(
      successMessage,
      orders: orders.cast<Map<String, dynamic>>(),
    );
  }

  Future<void> _clearCartAndNavigate() async {
    try {
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.clearCart();
        print('Cart cleared successfully');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        print('Navigating to orders page');
        context.go('/orders');
      }
    } catch (e) {
      print('Error clearing cart and navigating: $e');
      if (mounted) {
        try {
          context.go('/orders');
        } catch (navError) {
          print('Navigation error: $navError');
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      print('Widget not mounted, logging error: $message');
      return;
    }

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
        print('Failed to show error SnackBar: $e');
        print('Original error: $message');
      }
    });
  }

  void _showSuccessDialog(
    String message, {
    bool isBulkPayment = false,
    List<Map<String, dynamic>>? orders,
  }) {
    if (!mounted) return;

    String title = 'Order Placed Successfully!';
    if (isBulkPayment && orders != null && orders.length > 1) {
      title = '${orders.length} Orders Placed Successfully!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (orders != null && orders.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Order Numbers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...orders.map((order) => Text(
                    order['order_number'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
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
          onPressed: () => context.go('/cart'),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),
                        const SizedBox(height: 16),
                        _buildAddressSelectionSection(),
                        const SizedBox(height: 16),
                        if (!_useExistingAddress)
                          _buildShippingAddressSection(),
                        if (!_useExistingAddress) const SizedBox(height: 16),
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 100),
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
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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

  Widget _buildAddressSelectionSection() {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (addressProvider.addresses.isNotEmpty) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _useExistingAddress,
                        onChanged: (value) {
                          setState(() {
                            _useExistingAddress = value ?? false;
                            if (_useExistingAddress &&
                                _selectedAddress != null) {
                              _populateFormFromAddress(_selectedAddress!);
                            } else {
                              // Clear form
                              _nameController.clear();
                              _phoneController.clear();
                              _streetController.clear();
                              _areaController.clear();
                              _landmarkController.clear();
                              _cityController.clear();
                              _stateController.clear();
                              _pincodeController.clear();
                              _emailController.clear();
                            }
                          });
                        },
                        activeColor: const Color(0xFFFF7A2E),
                      ),
                      const Expanded(
                        child: Text(
                          'Use saved address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_useExistingAddress) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: addressProvider.addresses.map((address) {
                          return RadioListTile<AddressModel>(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      address.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF7A2E),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  address.phone,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${address.street}, ${address.city}, ${address.state} - ${address.pincode}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            value: address,
                            groupValue: _selectedAddress,
                            onChanged: (value) {
                              setState(() {
                                _selectedAddress = value;
                                if (value != null) {
                                  _populateFormFromAddress(value);
                                }
                              });
                            },
                            activeColor: const Color(0xFFFF7A2E),
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: !_useExistingAddress,
                        onChanged: (value) {
                          setState(() {
                            _useExistingAddress = !(value ?? false);
                            if (!_useExistingAddress) {
                              _selectedAddress = null;
                              // Clear form
                              _nameController.clear();
                              _phoneController.clear();
                              _streetController.clear();
                              _areaController.clear();
                              _landmarkController.clear();
                              _cityController.clear();
                              _stateController.clear();
                              _pincodeController.clear();
                              _emailController.clear();
                            }
                          });
                        },
                        activeColor: const Color(0xFFFF7A2E),
                      ),
                      const Expanded(
                        child: Text(
                          'Use a new address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No saved addresses found. Please enter a new address below.',
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
      },
    );
  }

  Widget _buildShippingAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_location_outlined,
                  color: Color(0xFFFF7A2E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Enter New Address',
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
                  flex: 2,
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
                  flex: 2,
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
                  flex: 1,
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pin *',
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
                        const Flexible(
                          child: Text(
                            'Cash on Delivery (COD)',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'Pay when your order is delivered',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'COD',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFFFF7A2E),
                    dense: true,
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
                        const Flexible(
                          child: Text(
                            'Pay Online',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'UPI, Cards, Net Banking, Wallets',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'Razorpay-UPI',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFFFF7A2E),
                    dense: true,
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
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
          child: SafeArea(
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
                      disabledBackgroundColor: Colors.grey[400],
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _processingPayment
                                      ? 'Processing Payment...'
                                      : 'Creating Order...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                              Flexible(
                                child: Text(
                                  _paymentMethod == 'COD'
                                      ? 'Place Order'
                                      : 'Proceed to Payment',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
          ),
        );
      },
    );
  }
}
