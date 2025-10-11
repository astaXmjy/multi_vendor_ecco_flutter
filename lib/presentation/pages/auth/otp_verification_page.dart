// lib/presentation/pages/auth/otp_verification_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../providers/user_provider.dart';
import '../../../api/services/auth_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String fullName;
  final bool isRegistration; // true for registration, false for login
  final Function(BuildContext)? onVerificationSuccess; // Callback with context

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.fullName,
    this.isRegistration = true,
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 300; // 5 minutes in seconds
  Timer? _countdownTimer;
  bool _canResend = false;
  int? _remainingAttempts;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 300; // 5 minutes
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getOTP().length == 6;
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // Handle OTP submission
  Future<void> _verifyOTP() async {
    if (!_isOTPComplete()) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      developer.log('Verifying OTP for email: ${widget.email}');

      final result = await _authService.verifyOTP(
        widget.email,
        _getOTP(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        developer.log('OTP verified successfully');

        // Update user provider with logged-in user data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userData = await _authService.getUserData();
        if (userData != null) {
          userProvider.setUserData(userData);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isRegistration
                  ? 'Account verified successfully! Welcome to Anugami.'
                  : 'Email verified successfully! You are now logged in.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Call the success callback if provided
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!(context);
        }
      } else {
        // Verification failed
        setState(() {
          _errorMessage = result['message'] ?? 'Invalid OTP. Please try again.';
          _remainingAttempts = result['remaining_attempts'];
        });

        // Clear OTP fields on error
        _clearOTP();

        // Show error with remaining attempts if available
        if (_remainingAttempts != null) {
          setState(() {
            _errorMessage =
                '${_errorMessage} ($_remainingAttempts attempts remaining)';
          });
        }
      }
    } catch (e) {
      developer.log('Error during OTP verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
        _clearOTP();
      }
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    if (mounted) {
      setState(() {
        _isResending = true;
        _errorMessage = null;
      });
    }

    try {
      developer.log('Resending OTP to email: ${widget.email}');

      final result = await _authService.resendOTP(widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      if (result['success']) {
        developer.log('OTP resent successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent successfully to your email'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _startResendTimer(); // Restart the timer
        _clearOTP(); // Clear current OTP
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      developer.log('Error resending OTP: $e');

      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    }
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Clear error when user starts typing
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }

      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, remove focus and auto-submit
        _focusNodes[index].unfocus();
        if (_isOTPComplete()) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _verifyOTP();
          });
        }
      }
    }
  }

  void _onOTPKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_otpControllers[index].text.isEmpty && index > 0) {
          // Move to previous field if current is empty
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: Text(
          widget.isRegistration ? 'Verify Your Email' : 'Email Verification',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF7A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Email verification icon
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A2E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 60,
                    color: Color(0xFFFF7A2E),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  widget.isRegistration
                      ? 'Verify Your Email'
                      : 'Enter Verification Code',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'We\'ve sent a 6-digit verification code to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // OTP Input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      List.generate(6, (index) => _buildOtpTextField(index)),
                ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Timer
                if (_resendCountdown > 0)
                  Text(
                    'Code expires in ${_formatTime(_resendCountdown)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Verify button
                ElevatedButton(
                  onPressed:
                      _isLoading || !_isOTPComplete() ? null : _verifyOTP,
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
                      : Text(
                          widget.isRegistration
                              ? 'Verify & Complete Registration'
                              : 'Verify Email',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 24),

                // Resend code option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive the code? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      onTap: _canResend && !_isResending ? _resendOTP : null,
                      child: Text(
                        _isResending
                            ? 'Sending...'
                            : _canResend
                                ? 'Resend Code'
                                : 'Resend (${_formatTime(_resendCountdown)})',
                        style: TextStyle(
                          fontSize: 14,
                          color: _canResend && !_isResending
                              ? const Color(0xFFFF7A2E)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Help section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A2E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF7A2E).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFF7A2E),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your email inbox and spam folder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF7A2E),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If you still don\'t receive the code, please try resending or contact support.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int index) {
    return SizedBox(
      width: 45,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onOTPKeyPressed(event, index),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          onChanged: (value) => _onOTPChanged(value, index),
          onTap: () {
            // Select all text when tapped
            _otpControllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _otpControllers[index].text.length,
            );
          },
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _errorMessage != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _errorMessage != null
                    ? Colors.red
                    : const Color(0xFFFF7A2E),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _errorMessage != null
                ? Colors.red.withOpacity(0.05)
                : Colors.grey[50],
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ),
    );
  }
}
