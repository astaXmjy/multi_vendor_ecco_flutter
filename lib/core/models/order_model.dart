// lib/core/models/order_model.dart
class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final int sellerId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final List<OrderAddress> addresses;
  final ShippingDetails? shipping;
  final PaymentDetails? payment;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.sellerId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.addresses,
    this.shipping,
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user'],
      sellerId: json['seller'],
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((address) => OrderAddress.fromJson(address))
              .toList() ??
          [],
      shipping: json['shipping'] != null
          ? ShippingDetails.fromJson(json['shipping'])
          : null,
      payment: json['payment'] != null
          ? PaymentDetails.fromJson(json['payment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user': userId,
      'seller': sellerId,
      'status': status,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'addresses': addresses.map((address) => address.toJson()).toList(),
      'shipping': shipping?.toJson(),
      'payment': payment?.toJson(),
    };
  }

  // ============== CANCEL ORDER FUNCTIONALITY ==============

  /// Check if order can be cancelled (created within 24 hours and in cancellable status)
  bool get canBeCancelled {
    // Check if order is in a cancellable status
    final cancellableStatuses = ['pending', 'confirmed'];
    if (!cancellableStatuses.contains(status.toLowerCase())) {
      return false;
    }

    // Check if order was created within 24 hours
    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    return timeDifference.inHours < 24;
  }

  /// Get time remaining to cancel order as a human-readable string
  String get timeRemainingToCancel {
    if (!_isWithin24Hours) {
      return 'Cannot cancel';
    }

    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    final hoursRemaining = 24 - timeDifference.inHours;

    if (hoursRemaining <= 0) {
      return 'Cannot cancel';
    } else if (hoursRemaining < 1) {
      final minutesRemaining = 60 - timeDifference.inMinutes % 60;
      return '$minutesRemaining min left';
    } else {
      return '${hoursRemaining}h left to cancel';
    }
  }

  /// Check if order is within 24 hours of creation
  bool get _isWithin24Hours {
    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    return timeDifference.inHours < 24;
  }

  /// Get detailed time remaining information
  Map<String, dynamic> get timeRemainingDetails {
    if (!_isWithin24Hours) {
      return {
        'canCancel': false,
        'message': 'Cancellation period expired',
        'hoursRemaining': 0,
        'minutesRemaining': 0,
      };
    }

    final now = DateTime.now();
    final timeDifference = now.difference(createdAt);
    final hoursRemaining = 24 - timeDifference.inHours;
    final minutesRemaining = 60 - timeDifference.inMinutes % 60;

    return {
      'canCancel': hoursRemaining > 0,
      'message': timeRemainingToCancel,
      'hoursRemaining': hoursRemaining > 0 ? hoursRemaining : 0,
      'minutesRemaining': hoursRemaining > 0 ? minutesRemaining : 0,
    };
  }

  /// Get cancellation eligibility reason
  String get cancellationStatusMessage {
    if (status.toLowerCase() == 'cancelled') {
      return 'Order is already cancelled';
    }

    if (!['pending', 'confirmed'].contains(status.toLowerCase())) {
      return 'Order cannot be cancelled in ${status.toLowerCase()} status';
    }

    if (!_isWithin24Hours) {
      return 'Cancellation period expired (24 hours limit)';
    }

    return 'Order can be cancelled';
  }

  // ============== EXISTING HELPER METHODS ==============

  /// Get order status display color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FF9800'; // Orange
      case 'confirmed':
        return '#2196F3'; // Blue
      case 'processing':
        return '#9C27B0'; // Purple
      case 'shipped':
        return '#3F51B5'; // Indigo
      case 'delivered':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      case 'returned':
        return '#757575'; // Grey
      default:
        return '#757575'; // Grey
    }
  }

  /// Check if order is completed
  bool get isCompleted => status.toLowerCase() == 'delivered';

  /// Check if order is active (not cancelled or returned)
  bool get isActive =>
      !['cancelled', 'returned'].contains(status.toLowerCase());

  /// Get formatted total amount
  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';

  /// Get shipping address
  OrderAddress? get shippingAddress {
    try {
      return addresses.firstWhere(
        (address) => address.addressType.toLowerCase() == 'shipping',
      );
    } catch (e) {
      return null;
    }
  }

  /// Get billing address
  OrderAddress? get billingAddress {
    try {
      return addresses.firstWhere(
        (address) => address.addressType.toLowerCase() == 'billing',
      );
    } catch (e) {
      return null;
    }
  }

  /// Get total items count
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order has tracking information
  bool get hasTrackingInfo => shipping?.hasTrackingInfo == true;

  /// Get display-friendly created date
  String get formattedCreatedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final String productId;
  final String name;
  final String? sku;
  final double price;
  final double? salePrice;
  final int quantity;
  final double finalPrice;
  final String status;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    this.sku,
    required this.price,
    this.salePrice,
    required this.quantity,
    required this.finalPrice,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order'],
      productId: json['product_id'],
      name: json['name'],
      sku: json['sku'],
      price: double.parse(json['price'].toString()),
      salePrice: json['sale_price'] != null
          ? double.parse(json['sale_price'].toString())
          : null,
      quantity: json['quantity'],
      finalPrice: double.parse(json['final_price'].toString()),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'product_id': productId,
      'name': name,
      'sku': sku,
      'price': price,
      'sale_price': salePrice,
      'quantity': quantity,
      'final_price': finalPrice,
      'status': status,
    };
  }

  /// Get effective price (sale price if available, otherwise regular price)
  double get effectivePrice => salePrice ?? price;

  /// Get formatted price
  String get formattedPrice => '₹${effectivePrice.toStringAsFixed(2)}';

  /// Get total item value
  double get totalValue => effectivePrice * quantity;

  /// Get formatted total value
  String get formattedTotalValue => '₹${totalValue.toStringAsFixed(2)}';
}

class OrderAddress {
  final int id;
  final int orderId;
  final String addressType;
  final String fullName;
  final String phone;
  final String email;
  final String street;
  final String area;
  final String? landmark;
  final String city;
  final String state;
  final String country;
  final String pincode;

  OrderAddress({
    required this.id,
    required this.orderId,
    required this.addressType,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.street,
    required this.area,
    this.landmark,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json['id'],
      orderId: json['order'],
      addressType: json['address_type'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      street: json['street'],
      area: json['area'],
      landmark: json['landmark'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'address_type': addressType,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'street': street,
      'area': area,
      'landmark': landmark,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }

  /// Get formatted full address
  String get fullAddress {
    final parts = <String>[
      street,
      area,
      if (landmark != null && landmark!.isNotEmpty) landmark!,
      city,
      state,
      country,
      pincode,
    ];
    return parts.join(', ');
  }

  /// Get short address (street, area, city)
  String get shortAddress {
    final parts = <String>[street, area, city];
    return parts.join(', ');
  }
}

// Updated ShippingDetails model for Shipmojo integration
class ShippingDetails {
  final int id;
  final int orderId;
  final String provider; // "shipmojo"
  final String? trackingId;
  final String? awbNumber; // awb_number from Shipmojo
  final String? trackingUrl;
  final String? courierName; // courier_name from Shipmojo
  final String? speed;
  final double weight;
  final double length;
  final double width;
  final double height;
  final String pickupLocation;
  final DateTime? pickupScheduled;
  final DateTime? expectedDelivery;
  final double? shippingCost;
  final String status;
  final List<dynamic> statusUpdates;

  // Shipmojo specific fields
  final String? shipmojoOrderId; // shipmojo_order_id
  final String? shipmojoReferenceId; // shipmojo_reference_id
  final String? courierCompanyId; // courier_company_id
  final String? courierCompanyService; // courier_company_service
  final String? warehouseId; // warehouse_id
  final String? lrNumber; // lr_number
  final String? labelUrl; // label_url
  final String? labelData; // label_data
  final String? pickupTokenNumber; // pickup_token_number
  final String? statusCode; // status_code
  final Map<String, dynamic> shipmojoResponse; // shipmojo_response
  final int? sellerId; // seller
  final bool courierAssigned; // courier_assigned
  final DateTime? courierAssignedAt; // courier_assigned_at
  final bool pickupScheduledManually; // pickup_scheduled_manually
  final bool isReturnOrder; // is_return_order
  final int? returnReasonId; // return_reason_id
  final String? returnReasonComment; // return_reason_comment
  final String? customerRequest; // customer_request

  ShippingDetails({
    required this.id,
    required this.orderId,
    required this.provider,
    this.trackingId,
    this.awbNumber,
    this.trackingUrl,
    this.courierName,
    this.speed,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.pickupLocation,
    this.pickupScheduled,
    this.expectedDelivery,
    this.shippingCost,
    required this.status,
    required this.statusUpdates,
    this.shipmojoOrderId,
    this.shipmojoReferenceId,
    this.courierCompanyId,
    this.courierCompanyService,
    this.warehouseId,
    this.lrNumber,
    this.labelUrl,
    this.labelData,
    this.pickupTokenNumber,
    this.statusCode,
    required this.shipmojoResponse,
    this.sellerId,
    required this.courierAssigned,
    this.courierAssignedAt,
    required this.pickupScheduledManually,
    required this.isReturnOrder,
    this.returnReasonId,
    this.returnReasonComment,
    this.customerRequest,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      id: json['id'],
      orderId: json['order'],
      provider: json['provider'] ?? 'shipmojo',
      trackingId: json['tracking_id'],
      awbNumber: json['awb_number'],
      trackingUrl: json['tracking_url'],
      courierName: json['courier_name'],
      speed: json['speed'],
      weight: double.parse(json['weight'].toString()),
      length: double.parse(json['length'].toString()),
      width: double.parse(json['width'].toString()),
      height: double.parse(json['height'].toString()),
      pickupLocation: json['pickup_location'] ?? '',
      pickupScheduled: json['pickup_scheduled'] != null
          ? DateTime.parse(json['pickup_scheduled'])
          : null,
      expectedDelivery: json['expected_delivery'] != null
          ? DateTime.parse(json['expected_delivery'])
          : null,
      shippingCost: json['shipping_cost'] != null
          ? double.parse(json['shipping_cost'].toString())
          : null,
      status: json['status'] ?? '',
      statusUpdates: json['status_updates'] ?? [],
      shipmojoOrderId: json['shipmojo_order_id'],
      shipmojoReferenceId: json['shipmojo_reference_id'],
      courierCompanyId: json['courier_company_id'],
      courierCompanyService: json['courier_company_service'],
      warehouseId: json['warehouse_id'],
      lrNumber: json['lr_number'],
      labelUrl: json['label_url'],
      labelData: json['label_data'],
      pickupTokenNumber: json['pickup_token_number'],
      statusCode: json['status_code'],
      shipmojoResponse: json['shipmojo_response'] ?? {},
      sellerId: json['seller'],
      courierAssigned: json['courier_assigned'] ?? false,
      courierAssignedAt: json['courier_assigned_at'] != null
          ? DateTime.parse(json['courier_assigned_at'])
          : null,
      pickupScheduledManually: json['pickup_scheduled_manually'] ?? false,
      isReturnOrder: json['is_return_order'] ?? false,
      returnReasonId: json['return_reason_id'],
      returnReasonComment: json['return_reason_comment'],
      customerRequest: json['customer_request'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'provider': provider,
      'tracking_id': trackingId,
      'awb_number': awbNumber,
      'tracking_url': trackingUrl,
      'courier_name': courierName,
      'speed': speed,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'pickup_location': pickupLocation,
      'pickup_scheduled': pickupScheduled?.toIso8601String(),
      'expected_delivery': expectedDelivery?.toIso8601String(),
      'shipping_cost': shippingCost,
      'status': status,
      'status_updates': statusUpdates,
      'shipmojo_order_id': shipmojoOrderId,
      'shipmojo_reference_id': shipmojoReferenceId,
      'courier_company_id': courierCompanyId,
      'courier_company_service': courierCompanyService,
      'warehouse_id': warehouseId,
      'lr_number': lrNumber,
      'label_url': labelUrl,
      'label_data': labelData,
      'pickup_token_number': pickupTokenNumber,
      'status_code': statusCode,
      'shipmojo_response': shipmojoResponse,
      'seller': sellerId,
      'courier_assigned': courierAssigned,
      'courier_assigned_at': courierAssignedAt?.toIso8601String(),
      'pickup_scheduled_manually': pickupScheduledManually,
      'is_return_order': isReturnOrder,
      'return_reason_id': returnReasonId,
      'return_reason_comment': returnReasonComment,
      'customer_request': customerRequest,
    };
  }

  // Helper methods for shipping status
  bool get hasTrackingInfo => awbNumber != null && awbNumber!.isNotEmpty;
  bool get isShipped =>
      status.toLowerCase().contains('shipped') || courierAssigned;
  bool get isDelivered => status.toLowerCase().contains('delivered');
  bool get isCancelled => status.toLowerCase().contains('cancelled');

  String get displayStatus {
    if (isDelivered) return 'Delivered';
    if (isCancelled) return 'Cancelled';
    if (isShipped) return 'Shipped';
    if (courierAssigned) return 'Courier Assigned';
    if (shipmojoOrderId != null) return 'Processing';
    return 'Pending';
  }
}

// Updated PaymentDetails model for Razorpay integration
class PaymentDetails {
  final int id;
  final int orderId;
  final String method;
  final String? transactionId;
  final String paymentStatus;
  final double? amountPaid;
  final String? refundStatus;
  final double? refundAmount;

  // Razorpay specific fields
  final String? razorpayOrderId; // razorpay_order_id
  final String? razorpayPaymentId; // razorpay_payment_id
  final String? razorpaySignature; // razorpay_signature
  final String? razorpayStatus; // razorpay_status
  final String? paymentUrl; // payment_url
  final String? callbackUrl; // callback_url
  final String? redirectUrl; // redirect_url
  final Map<String, dynamic> razorpayResponse; // razorpay_response
  final Map<String, dynamic> paymentMethodDetails; // payment_method_details
  final double? feeAmount; // fee_amount
  final double? taxAmount; // tax_amount
  final DateTime createdAt; // created_at
  final DateTime updatedAt; // updated_at
  final DateTime? paidAt; // paid_at

  PaymentDetails({
    required this.id,
    required this.orderId,
    required this.method,
    this.transactionId,
    required this.paymentStatus,
    this.amountPaid,
    this.refundStatus,
    this.refundAmount,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.razorpayStatus,
    this.paymentUrl,
    this.callbackUrl,
    this.redirectUrl,
    required this.razorpayResponse,
    required this.paymentMethodDetails,
    this.feeAmount,
    this.taxAmount,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      id: json['id'],
      orderId: json['order'],
      method: json['method'],
      transactionId: json['transaction_id'],
      paymentStatus: json['payment_status'],
      amountPaid: json['amount_paid'] != null
          ? double.parse(json['amount_paid'].toString())
          : null,
      refundStatus: json['refund_status'],
      refundAmount: json['refund_amount'] != null
          ? double.parse(json['refund_amount'].toString())
          : null,
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpaySignature: json['razorpay_signature'],
      razorpayStatus: json['razorpay_status'],
      paymentUrl: json['payment_url'],
      callbackUrl: json['callback_url'],
      redirectUrl: json['redirect_url'],
      razorpayResponse: json['razorpay_response'] ?? {},
      paymentMethodDetails: json['payment_method_details'] ?? {},
      feeAmount: json['fee_amount'] != null
          ? double.parse(json['fee_amount'].toString())
          : null,
      taxAmount: json['tax_amount'] != null
          ? double.parse(json['tax_amount'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'method': method,
      'transaction_id': transactionId,
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'refund_status': refundStatus,
      'refund_amount': refundAmount,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'razorpay_status': razorpayStatus,
      'payment_url': paymentUrl,
      'callback_url': callbackUrl,
      'redirect_url': redirectUrl,
      'razorpay_response': razorpayResponse,
      'payment_method_details': paymentMethodDetails,
      'fee_amount': feeAmount,
      'tax_amount': taxAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  // Helper methods for payment status
  bool get isPaid =>
      paymentStatus.toLowerCase() == 'paid' ||
      paymentStatus.toLowerCase() == 'captured';
  bool get isPending => paymentStatus.toLowerCase() == 'pending';
  bool get isFailed => paymentStatus.toLowerCase() == 'failed';
  bool get isRefunded => paymentStatus.toLowerCase().contains('refund');
  bool get isCOD => method.toUpperCase() == 'COD';
  bool get isOnlinePayment => !isCOD;

  String get displayStatus {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'captured':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'partially_refunded':
        return 'Partially Refunded';
      case 'refund_initiated':
        return 'Refund Processing';
      default:
        return paymentStatus;
    }
  }
}
