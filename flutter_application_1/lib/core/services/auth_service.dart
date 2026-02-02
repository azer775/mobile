import 'package:flutter/foundation.dart';

/// Simple authentication service
/// In a real app, this would connect to a backend API
class AuthService {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  String? _currentUser;
  String? _currentUserEmail;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Get current user name
  String? get currentUser => _currentUser;

  /// Get current user email
  String? get currentUserEmail => _currentUserEmail;

  /// Login with email and password
  /// Returns true if login successful, false otherwise
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call
    // For demo purposes, accept any non-empty credentials
    if (email.isNotEmpty && password.isNotEmpty) {
      // Extract username from email
      _currentUserEmail = email;
      _currentUser = email.split('@').first.toUpperCase();
      
      if (kDebugMode) {
        print('User logged in: $_currentUser');
      }
      return true;
    }
    return false;
  }

  /// Login with specific credentials (for demo/testing)
  Future<bool> loginWithCredentials(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // Demo accounts
    final validCredentials = {
      'admin@test.com': 'admin123',
      'user@test.com': 'user123',
    };

    if (validCredentials[email] == password) {
      _currentUserEmail = email;
      _currentUser = email.split('@').first.toUpperCase();
      return true;
    }
    return false;
  }

  /// Logout current user
  Future<void> logout() async {
    _currentUser = null;
    _currentUserEmail = null;
  }
}
