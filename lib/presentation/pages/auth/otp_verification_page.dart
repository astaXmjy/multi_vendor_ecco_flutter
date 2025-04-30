// lib/presentation/pages/auth/otp_verification_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../../../providers/user_provider.dart';
import '../../../api/services/auth_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Map<String, dynamic>? registrationData; // User registration data
  final bool isUserRegistered; // Flag to know if user is already registered
  final Function(BuildContext)? onVerificationSuccess; // Callback with context

  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    this.registrationData,
    this.isUserRegistered = false,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _countdownTimer;
  bool _canResend = false;

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
    _resendCountdown = 30;
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

  // Handle OTP submission
  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();
    String otpCode =
        _otpControllers.map((controller) => controller.text).join();

    if (otpCode.length != 6) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please enter the complete 6-digit OTP code';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Create a PhoneAuthCredential with the verification ID and OTP code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpCode,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // If we got here, the OTP is verified
      developer.log('OTP verified successfully');

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Call the success callback if provided
      if (widget.onVerificationSuccess != null) {
        widget.onVerificationSuccess!(context);
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth error: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Invalid OTP code. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error during OTP verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    if (!_canResend) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (on Android)
          await _auth.signInWithCredential(credential);

          if (mounted && widget.onVerificationSuccess != null) {
            widget.onVerificationSuccess!(context);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('Verification failed: ${e.message}');

          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  e.message ?? 'Failed to send OTP. Please try again.';
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('OTP sent successfully.');

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP has been sent again'),
                backgroundColor: Colors.green,
              ),
            );
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      developer.log('Error sending OTP: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text(
          'OTP Verification',
          style: TextStyle(color: Colors.white),
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
                // Icon
                const Icon(
                  Icons.message,
                  size: 80,
                  color: Color(0xFFFF7A2E),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'We have sent the verification code to\n${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

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
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
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
                      : const Text('Verify & Proceed',
                          style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 24),

                // Resend code option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive the code? ',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _canResend ? _resendOTP : null,
                        child: Text(
                          _canResend
                              ? 'Resend'
                              : 'Resend in $_resendCountdown seconds',
                          style: TextStyle(
                            color: _canResend
                                ? const Color(0xFFFF7A2E)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
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
      height: 50,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field if not the last field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last field filled, hide keyboard
              _focusNodes[index].unfocus();
              // Auto-submit when all fields are filled
              Future.delayed(const Duration(milliseconds: 100), () {
                final allFilled = _otpControllers
                    .every((controller) => controller.text.isNotEmpty);
                if (allFilled) {
                  _verifyOTP();
                }
              });
            }
          }
        },
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
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF7A2E), width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}
