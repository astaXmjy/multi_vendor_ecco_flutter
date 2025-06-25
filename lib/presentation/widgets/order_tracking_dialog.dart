import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/services/order_service.dart';
import '../../core/models/order_model.dart';
import '../../core/models/tracking_model.dart';

class OrderTrackingDialog extends StatefulWidget {
  final OrderModel order;
  final OrderService orderService;

  const OrderTrackingDialog({
    Key? key,
    required this.order,
    required this.orderService,
  }) : super(key: key);

  @override
  State<OrderTrackingDialog> createState() => _OrderTrackingDialogState();
}

class _OrderTrackingDialogState extends State<OrderTrackingDialog> {
  bool _isLoading = true;
  TrackingModel? _trackingData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
  }

  Future<void> _fetchTrackingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.orderService.trackOrder(widget.order.id);

      if (result['success']) {
        setState(() {
          _trackingData = TrackingModel.fromJson(result['data']);
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to fetch tracking data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Content
            Flexible(
              child: _isLoading
                  ? _buildLoadingView()
                  : _error != null
                      ? _buildErrorView()
                      : _buildTrackingContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFF7A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Your Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Order #${widget.order.orderNumber}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF7A2E),
            ),
            SizedBox(height: 16),
            Text(
              'Loading tracking information...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to fetch tracking information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: _fetchTrackingData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    if (_trackingData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No tracking data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status
          _buildCurrentStatus(),
          const SizedBox(height: 24),

          // Shipping Details
          if (_trackingData!.shippingDetails != null) ...[
            _buildShippingDetails(),
            const SizedBox(height: 24),
          ],

          // Status History
          if (_trackingData!.statusHistory.isNotEmpty) ...[
            _buildStatusHistory(),
          ] else ...[
            _buildBasicTracking(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final status = _trackingData!.status;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatStatus(status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDetails() {
    final shipping = _trackingData!.shippingDetails!;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (shipping.courierName != null) ...[
              _buildDetailRow('Courier', shipping.courierName!),
              const SizedBox(height: 8),
            ],
            if (shipping.awbCode != null) ...[
              _buildDetailRow('AWB Number', shipping.awbCode!),
              const SizedBox(height: 8),
            ],
            if (shipping.trackingId != null) ...[
              _buildDetailRow('Tracking ID', shipping.trackingId!),
              const SizedBox(height: 8),
            ],
            _buildDetailRow('Provider', shipping.provider),
            if (shipping.pickupDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Pickup Date',
                  DateFormat('MMM dd, yyyy').format(shipping.pickupDate!)),
            ],
            if (shipping.trackingUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchTrackingUrl(shipping.trackingUrl!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Track on Website'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A2E),
                    side: const BorderSide(color: Color(0xFFFF7A2E)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracking History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _trackingData!.statusHistory.length,
          itemBuilder: (context, index) {
            final update = _trackingData!.statusHistory[index];
            final isLast = index == _trackingData!.statusHistory.length - 1;

            return _buildTimelineItem(update, isLast);
          },
        ),
      ],
    );
  }

  Widget _buildBasicTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSimpleTimeline(),
      ],
    );
  }

  Widget _buildSimpleTimeline() {
    final currentStatus = _trackingData!.status.toLowerCase();

    final statuses = [
      {'key': 'pending', 'label': 'Order Placed'},
      {'key': 'confirmed', 'label': 'Order Confirmed'},
      {'key': 'processing', 'label': 'Processing'},
      {'key': 'shipped', 'label': 'Shipped'},
      {'key': 'delivered', 'label': 'Delivered'},
    ];

    return Column(
      children: statuses.map((statusMap) {
        final statusKey = statusMap['key']!;
        final statusLabel = statusMap['label']!;
        final isCompleted = _isStatusCompleted(statusKey, currentStatus);
        final isCurrent = statusKey == currentStatus;
        final isLast = statusKey == 'delivered';

        return _buildSimpleTimelineItem(
            statusLabel, isCompleted, isCurrent, isLast);
      }).toList(),
    );
  }

  Widget _buildSimpleTimelineItem(
      String label, bool isCompleted, bool isCurrent, bool isLast) {
    final color =
        isCompleted || isCurrent ? const Color(0xFFFF7A2E) : Colors.grey[300]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: isCompleted || isCurrent ? Colors.white : color,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                height: 40,
                width: 2,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color:
                        isCompleted || isCurrent ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Current Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(TrackingUpdateModel update, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getStatusColor(update.status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(update.status),
                color: Colors.white,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                height: 40,
                width: 2,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(update.status),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(update.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (update.location != null && update.location!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          update.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (update.activity != null && update.activity!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    update.activity!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'order created':
      case 'order created in shiprocket':
        return Colors.orange;
      case 'confirmed':
      case 'pickup scheduled':
        return Colors.blue;
      case 'processing':
      case 'shipped':
        return Colors.purple;
      case 'out for delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'order created':
      case 'order created in shiprocket':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
      case 'pickup scheduled':
        return Icons.inventory;
      case 'shipped':
        return Icons.local_shipping;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatStatus(String status) {
    return status
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  bool _isStatusCompleted(String statusKey, String currentStatus) {
    final statusOrder = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered'
    ];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final statusIndex = statusOrder.indexOf(statusKey);

    return currentIndex >= statusIndex &&
        currentIndex != -1 &&
        statusIndex != -1;
  }

  Future<void> _launchTrackingUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open tracking URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
