// lib/providers/address_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../api/services/address_service.dart';
import '../core/models/address_model.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get default address if exists
  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  // Load all addresses
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.getAddresses();

      if (result['success']) {
        _addresses = List<AddressModel>.from(result['data']);
        _isLoading = false;
        notifyListeners();
      } else {
        _error = result['message'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new address
  Future<Map<String, dynamic>> addAddress(AddressModel address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.addAddress(address.toJson());

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update address
  Future<Map<String, dynamic>> updateAddress(
      String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.updateAddress(id, data);

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Set address as default
  // Set address as default
  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find the address to update
      final address = _addresses.firstWhere((addr) => addr.id == id);

      // Create a copy with is_default set to true
      final updatedAddress = address.copyWith(isDefault: true);

      // Use the existing updateAddress method since it works
      final result =
          await _addressService.updateAddress(id, updatedAddress.toJson());

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete address
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.deleteAddress(id);

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
