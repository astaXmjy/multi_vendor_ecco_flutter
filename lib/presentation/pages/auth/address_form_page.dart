// lib/presentation/pages/auth/address_form_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../api/services/auth_service.dart';
import '../../../core/models/address_model.dart';
import '../../../providers/user_provider.dart';

class AddressFormPage extends StatefulWidget {
  final String fullName;
  final String phone;

  const AddressFormPage({
    Key? key,
    required this.fullName,
    required this.phone,
  }) : super(key: key);

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedAddressType = 'home';
  bool _isDefault = true;
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final addressData = AddressModel(
      addressType: _selectedAddressType,
      fullName: widget.fullName,
      phone: widget.phone,
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      final result = await _authService.addAddress(addressData.toJson());

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address added successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Make sure the user provider has the latest data
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          if (!userProvider.isLoggedIn) {
            final userData = await _authService.getUserData();
            if (userData != null) {
              userProvider.setUserData(userData);
            }
          }

          // Navigate to the home page
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to add address';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text(
          'Add Delivery Address',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF7A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Your Delivery Address',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Personal details section (read-only)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name: ${widget.fullName}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Phone: ${widget.phone}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address type selection
                      _buildFormLabel('Address Type', false),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAddressType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _addressTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value.toUpperCase(),
                                  style: const TextStyle(
                                    textBaseline: TextBaseline.alphabetic,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedAddressType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Street Address
                      _buildFormLabel('Street Address', true),
                      _buildTextField(
                        controller: _streetController,
                        hintText: 'House/Flat number, Building, Street',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your street address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // City
                      _buildFormLabel('City', true),
                      _buildTextField(
                        controller: _cityController,
                        hintText: 'Enter your city',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // State and Pincode
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('State', true),
                                _buildTextField(
                                  controller: _stateController,
                                  hintText: 'Enter state',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('Pincode', true),
                                _buildTextField(
                                  controller: _pincodeController,
                                  hintText: 'Enter pincode',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Country
                      _buildFormLabel('Country', true),
                      _buildTextField(
                        controller: _countryController,
                        hintText: 'Enter your country',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Set as default address
                      Row(
                        children: [
                          Checkbox(
                            value: _isDefault,
                            activeColor: const Color(0xFFFF7A2E),
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Set as default address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Display error message if any
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A2E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Address',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Skip button
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Make sure the user provider has the latest data before skipping
                                Provider.of<UserProvider>(context,
                                        listen: false)
                                    .initialize();
                                // Skip adding address and go straight to home
                                context.go('/home');
                              },
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Color(0xFFFF7A2E),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF7A2E)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
