// lib/presentation/pages/orders/orders_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../api/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../widgets/order_tracking_dialog.dart';
import '../shared/custom_app_bar.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _orderService.getMyOrders();

      if (result['success']) {
        final List<dynamic> ordersData =
            result['data']['results'] ?? result['data'];
        setState(() {
          _orders =
              ordersData.map((order) => OrderModel.fromJson(order)).toList();
        });
      } else {
        _showError(result['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(PaymentDetails? payment) {
    if (payment == null) return 'N/A';
    return payment.displayStatus;
  }

  Color _getPaymentStatusColor(PaymentDetails? payment) {
    if (payment == null) return Colors.grey;

    if (payment.isPaid) return Colors.green;
    if (payment.isPending) return Colors.orange;
    if (payment.isFailed) return Colors.red;
    if (payment.isRefunded) return Colors.blue;

    return Colors.grey;
  }

  String _getPaymentMethodText(PaymentDetails? payment) {
    if (payment == null) return 'N/A';

    switch (payment.method.toUpperCase()) {
      case 'COD':
        return 'Cash on Delivery';
      case 'RAZORPAY-UPI':
        return 'UPI';
      case 'RAZORPAY-CARD':
        return 'Card';
      case 'RAZORPAY-WALLET':
        return 'Wallet';
      case 'RAZORPAY-NETBANKING':
        return 'Net Banking';
      default:
        return payment.method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'My Orders',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A2E)),
              ),
            )
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: const Color(0xFFFF7A2E),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04,
                      vertical: 16,
                    ),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start shopping to see your orders here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Use Go Router for navigation
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Start Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(order.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Items (${order.items.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7A2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  '... and ${order.items.length - 2} more items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Payment and shipping info row
            Row(
              children: [
                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(order.payment)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPaymentStatusText(order.payment),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getPaymentStatusColor(order.payment),
                          ),
                        ),
                      ),
                      if (order.payment != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getPaymentMethodText(order.payment),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Total amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
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

            // Shipping info if available
            if (order.shipping != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.shipping!.displayStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (order.shipping!.awbNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'AWB: ${order.shipping!.awbNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (order.shipping!.courierName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'via ${order.shipping!.courierName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Track Order Button
                  if (order.shipping!.hasTrackingInfo)
                    TextButton(
                      onPressed: () => _showTrackingDialog(order),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor:
                            const Color(0xFFFF7A2E).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Track',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF7A2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Action buttons for certain statuses
            if (_shouldShowActionButtons(order)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildActionButtons(order),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowActionButtons(OrderModel order) {
    final status = order.status.toLowerCase();
    return status == 'pending' ||
        status == 'confirmed' ||
        (order.payment != null && order.payment!.isPending);
  }

  Widget _buildActionButtons(OrderModel order) {
    return Row(
      children: [
        // Cancel order button (if applicable)
        if (order.status.toLowerCase() == 'pending' ||
            order.status.toLowerCase() == 'confirmed')
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelOrderDialog(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel Order',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

        if (order.status.toLowerCase() == 'pending' ||
            order.status.toLowerCase() == 'confirmed')
          const SizedBox(width: 12),

        // Pay now button (if payment is pending)
        if (order.payment != null &&
            order.payment!.isPending &&
            !order.payment!.isCOD)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _initiatePayment(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  // Show tracking dialog
  void _showTrackingDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => OrderTrackingDialog(
        order: order,
        orderService: _orderService,
      ),
    );
  }

  // Show cancel order confirmation
  void _showCancelOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
            'Are you sure you want to cancel order #${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // Cancel order
  Future<void> _cancelOrder(OrderModel order) async {
    try {
      // Implement cancel order API call here
      _showError('Order cancellation feature will be implemented soon');
    } catch (e) {
      _showError('Failed to cancel order: $e');
    }
  }

  // Initiate payment for pending orders
  Future<void> _initiatePayment(OrderModel order) async {
    try {
      final result = await _orderService.initiatePayment(orderId: order.id);

      if (result['success']) {
        // Handle payment initiation
        _showError(
            'Payment feature will be implemented with Razorpay integration');
      } else {
        _showError(result['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      _showError('Payment error: $e');
    }
  }
}
