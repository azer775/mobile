import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage secret credentials stored securely
class SecretCredentialsService {
  static SecretCredentialsService? _instance;
  static SecretCredentialsService get instance {
    _instance ??= SecretCredentialsService._();
    return _instance!;
  }

  SecretCredentialsService._();

  final _storage = const FlutterSecureStorage();

  static const _emailKey = 'secret_admin_email';
  static const _passwordKey = 'secret_admin_password';

  /// Check if secret credentials are set
  Future<bool> hasCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    return email != null && email.isNotEmpty && password != null && password.isNotEmpty;
  }

  /// Save secret credentials
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Validate credentials against stored ones
  Future<bool> validateCredentials(String email, String password) async {
    final storedEmail = await _storage.read(key: _emailKey);
    final storedPassword = await _storage.read(key: _passwordKey);

    // If no credentials stored, allow any login (fallback)
    if (storedEmail == null || storedPassword == null) {
      return true;
    }

    return email == storedEmail && password == storedPassword;
  }

  /// Get stored email (for display purposes only)
  Future<String?> getStoredEmail() async {
    return await _storage.read(key: _emailKey);
  }
  Future<String?> getStoredPassword() async {
    return await _storage.read(key: _passwordKey);
  }


  /// Clear stored credentials
  Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
