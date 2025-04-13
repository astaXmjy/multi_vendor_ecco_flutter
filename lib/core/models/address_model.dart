// lib/core/models/address_model.dart
class AddressModel {
  final String? id;
  final String addressType;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.addressType,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      addressType: json['address_type'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_type': addressType,
      'full_name': fullName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }
}
