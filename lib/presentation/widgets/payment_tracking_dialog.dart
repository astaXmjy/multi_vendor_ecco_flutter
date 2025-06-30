import 'package:flutter/material.dart';

import '../../api/services/order_service.dart';

class PaymentTrackingDialog extends StatefulWidget {
  final int orderId;
  final String transactionId;
  final OrderService orderService;
  final Function(bool success) onPaymentComplete;

  const PaymentTrackingDialog({
    Key? key,
    required this.orderId,
    required this.transactionId,
    required this.orderService,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentTrackingDialog> createState() => _PaymentTrackingDialogState();
}

class _PaymentTrackingDialogState extends State<PaymentTrackingDialog> {
  String _status = 'Checking payment status...';
  bool _isSuccess = false;
  bool _isComplete = false;
  late Stream<int> _statusCheckStream;

  @override
  void initState() {
    super.initState();
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusCheckStream = Stream.periodic(
      const Duration(seconds: 3),
      (count) => count,
    ).take(20); // Check for 1 minute maximum

    _statusCheckStream.listen((count) async {
      if (_isComplete || !mounted) return;

      try {
        final result =
            await widget.orderService.checkPaymentStatus(widget.orderId);

        if (!mounted) return;

        if (result['success']) {
          final paymentStatus = result['data']['payment_status'];
          final phonepeStatus = result['data']['status'];

          setState(() {
            if (paymentStatus == 'paid' || phonepeStatus == 'PAYMENT_SUCCESS') {
              _status = 'Payment successful!';
              _isSuccess = true;
              _isComplete = true;
            } else if (paymentStatus == 'failed' ||
                phonepeStatus == 'PAYMENT_DECLINED' ||
                phonepeStatus == 'PAYMENT_ERROR' ||
                phonepeStatus == 'PAYMENT_CANCELLED') {
              _status = 'Payment failed. Please try again.';
              _isSuccess = false;
              _isComplete = true;
            } else {
              _status = 'Payment in progress... Please complete the payment.';
            }
          });

          if (_isComplete) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              widget.onPaymentComplete(_isSuccess);
            }
          }
        }
      } catch (e) {
        if (!mounted) return;

        if (count > 15) {
          // After 45 seconds
          setState(() {
            _status = 'Unable to verify payment. Please check your orders.';
            _isComplete = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            widget.onPaymentComplete(false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isComplete)
              const CircularProgressIndicator(
                color: Color(0xFFFF7A2E),
              )
            else
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error,
                color: _isSuccess ? Colors.green : Colors.red,
                size: 64,
              ),
            const SizedBox(height: 24),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_isComplete)
              Text(
                'Transaction ID: ${widget.transactionId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            if (_isComplete) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onPaymentComplete(_isSuccess),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckStream.drain();
    super.dispose();
  }
}
