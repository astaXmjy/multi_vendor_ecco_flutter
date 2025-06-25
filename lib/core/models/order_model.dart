class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final List<OrderItemModel> items;
  final List<OrderAddressModel> addresses;
  final ShippingDetailsModel? shipping;
  final PaymentDetailsModel? payment;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.addresses,
    this.shipping,
    this.payment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      addresses: (json['addresses'] as List<dynamic>)
          .map((address) => OrderAddressModel.fromJson(address))
          .toList(),
      shipping: json['shipping'] != null
          ? ShippingDetailsModel.fromJson(json['shipping'])
          : null,
      payment: json['payment'] != null
          ? PaymentDetailsModel.fromJson(json['payment'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final double? salePrice;
  final int quantity;
  final double finalPrice;
  final String status;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    this.salePrice,
    required this.quantity,
    required this.finalPrice,
    required this.status,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      salePrice: json['sale_price'] != null
          ? double.parse(json['sale_price'].toString())
          : null,
      quantity: json['quantity'],
      finalPrice: double.parse(json['final_price'].toString()),
      status: json['status'],
    );
  }
}

class OrderAddressModel {
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

  OrderAddressModel({
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

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
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
}

class ShippingDetailsModel {
  final String provider;
  final String? trackingId;
  final String? awbNumber;
  final String? courierName;
  final String status;

  ShippingDetailsModel({
    required this.provider,
    this.trackingId,
    this.awbNumber,
    this.courierName,
    required this.status,
  });

  factory ShippingDetailsModel.fromJson(Map<String, dynamic> json) {
    return ShippingDetailsModel(
      provider: json['provider'],
      trackingId: json['tracking_id'],
      awbNumber: json['awb_number'],
      courierName: json['courier_name'],
      status: json['status'],
    );
  }
}

class PaymentDetailsModel {
  final String method;
  final String paymentStatus;
  final double? amountPaid;
  final String? transactionId;
  final String? phonepeStatus;

  PaymentDetailsModel({
    required this.method,
    required this.paymentStatus,
    this.amountPaid,
    this.transactionId,
    this.phonepeStatus,
  });

  factory PaymentDetailsModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsModel(
      method: json['method'],
      paymentStatus: json['payment_status'],
      amountPaid: json['amount_paid'] != null
          ? double.parse(json['amount_paid'].toString())
          : null,
      transactionId: json['transaction_id'],
      phonepeStatus: json['phonepe_status'],
    );
  }
}
