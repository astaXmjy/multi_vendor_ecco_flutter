// lib/presentation/pages/auth/create_account_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../api/services/auth_service.dart';
import '../../../providers/user_provider.dart';
import 'otp_verification_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(
              const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7A2E), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Colors.black, // Calendar text
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });

    // Collect all registration data
    final userData = {
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'password': _passwordController.text,
      'confirm_password': _confirmPasswordController.text,
    };

    // Add optional fields if provided
    if (_selectedDate != null) {
      userData['date_of_birth'] =
          DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    if (_selectedGender.isNotEmpty) {
      userData['gender'] = _selectedGender.toLowerCase();
    }

    try {
      developer
          .log('Starting registration process with email OTP verification');

      // Register user with backend - this will send email OTP
      final result = await _authService.register(userData);

      setState(() {
        _isLoading = false;
      });

      if (!result['success']) {
        // Registration failed, show error
        _handleRegistrationError(result);
        return;
      }

      // Registration successful, navigate to OTP verification page
      developer.log('Registration successful, navigating to OTP verification');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              email: result['email'] ?? _emailController.text.trim(),
              fullName: _fullNameController.text.trim(),
              isRegistration: true,
              onVerificationSuccess: (BuildContext context) async {
                // After successful OTP verification, user is logged in automatically
                // Update the user provider
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final userData = await _authService.getUserData();
                if (userData != null) {
                  userProvider.setUserData(userData);
                }

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Account created successfully! Welcome to Anugami.'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to home or address form as needed
                  // You can modify this navigation based on your app flow
                  context.go(
                      '/home'); // or wherever you want to navigate after registration
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error in registration process: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void _handleRegistrationError(Map<String, dynamic> result) {
    // Handle different types of errors from the backend
    if (result['errors'] != null && result['errors'] is Map) {
      // Field-specific errors
      setState(() {
        _fieldErrors = result['errors'];
      });

      // Show a general error message
      if (result['message'] != null) {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } else if (result['message'] != null) {
      // General error message
      setState(() {
        _errorMessage = result['message'];
      });
    } else {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    }

    // Show snackbar with error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5), // Light cream background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with gradient
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF7A2E), // Orange
                              Color(0xFFFF4947), // Coral
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create your account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Join our community and start shopping',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Registration form
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display general error message if any
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade800, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                            color: Colors.red.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Full Name
                            _buildFormLabel('Full Name', true),
                            _buildTextField(
                              controller: _fullNameController,
                              hintText: 'Enter your full name',
                              fieldName: 'full_name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters long';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email
                            _buildFormLabel('Email', true),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'your@email.com',
                              fieldName: 'email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Phone
                            _buildFormLabel('Phone', true),
                            _buildTextField(
                              controller: _phoneController,
                              hintText: 'Enter your phone number',
                              fieldName: 'phone',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                final cleanPhone =
                                    value.replaceAll(RegExp(r'[^\d]'), '');
                                if (cleanPhone.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Date of Birth and Gender
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel('Date of Birth', false),
                                      InkWell(
                                        onTap: () => _selectDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _selectedDate == null
                                                      ? 'dd-mm-yyyy'
                                                      : DateFormat('dd-MM-yyyy')
                                                          .format(
                                                              _selectedDate!),
                                                  style: TextStyle(
                                                    color: _selectedDate == null
                                                        ? Colors.grey.shade500
                                                        : Colors.black,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today,
                                                  size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel('Gender', false),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedGender,
                                            isExpanded: true,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            items: _genderOptions
                                                .map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                _selectedGender = newValue!;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Password
                            _buildFormLabel('Password', true),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Create a password',
                              fieldName: 'password',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password
                            _buildFormLabel('Confirm Password', true),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm your password',
                              fieldName: 'confirm_password',
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Info box about email verification
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'We\'ll send a verification code to your email address to complete registration.',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Create Account button
                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleRegistration,
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
                                      'Create Account',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),

                            const SizedBox(height: 16),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to login screen
                                    context.go('/login');
                                  },
                                  child: const Text(
                                    'Log in',
                                    style: TextStyle(
                                      color: Color(0xFFFF7A2E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    required String fieldName,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    // Check if there are field-specific errors from the API
    String? fieldError;
    if (_fieldErrors != null && _fieldErrors!.containsKey(fieldName)) {
      if (_fieldErrors![fieldName] is List) {
        fieldError = (_fieldErrors![fieldName] as List).first.toString();
      } else if (_fieldErrors![fieldName] is String) {
        fieldError = _fieldErrors![fieldName];
      }
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
        suffixIcon: suffixIcon,
        errorText: fieldError,
      ),
      validator: validator,
    );
  }
}
