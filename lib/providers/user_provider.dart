// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../api/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user's full name
  String get fullName => _userData != null && _userData!.containsKey('full_name')
      ? _userData!['full_name']
      : 'Guest User';

  // Get user's email
  String get email => _userData != null && _userData!.containsKey('email')
      ? _userData!['email']
      : '';

  // Get user's ID
  String get userId => _userData != null && _userData!.containsKey('id')
      ? _userData!['id'].toString()
      : '';

  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _userData = await _authService.getUserData();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set user data after login or registration
  void setUserData(Map<String, dynamic> userData) {
    _userData = userData;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoggedIn = false;
      _userData = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}