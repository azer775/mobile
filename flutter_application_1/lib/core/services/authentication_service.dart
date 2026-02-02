import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../data/models/dto/authentication_request_dto.dart';
import '../constants/api_constants.dart';
import 'secret_credentials_service.dart';

/// Service responsible for authenticating with the backend API.
/// Uses the stored secret credentials to obtain a JWT token.
class AuthenticationService {
  // ============================================================
  // SINGLETON PATTERN
  // ============================================================
  static AuthenticationService? _instance;
  static AuthenticationService get instance {
    _instance ??= AuthenticationService._();
    return _instance!;
  }

  AuthenticationService._();

  // ============================================================
  // CONFIGURATION
  // ============================================================
  
  /// Login endpoint path
  static const String _loginEndpoint = '/auth/login';

  // ============================================================
  // DEPENDENCIES
  // ============================================================
  
  final SecretCredentialsService _credentialsService = SecretCredentialsService.instance;

  // ============================================================
  // PUBLIC METHODS
  // ============================================================

  /// Authenticates with the backend using stored secret credentials.
  /// 
  /// Returns the JWT token if authentication is successful.
  /// Throws an [AuthenticationException] if authentication fails.
  /// 
  /// Usage:
  /// ```dart
  /// try {
  ///   final token = await AuthenticationService.instance.authenticate();
  ///   // Use token for subsequent API calls
  /// } on AuthenticationException catch (e) {
  ///   // Handle authentication error
  /// }
  /// ```
  Future<String> authenticate() async {
    // Step 1: Get stored credentials
    final credentials = await _getStoredCredentials();
    
    // Step 2: Send POST request to login endpoint
    final response = await _sendLoginRequest(credentials);
    
    // Step 3: Parse and return the JWT token
    return _extractTokenFromResponse(response);
  }

  /// Authenticates with the backend using provided credentials.
  /// Useful for testing or when you want to use different credentials.
  /// 
  /// Returns the JWT token if authentication is successful.
  /// Throws an [AuthenticationException] if authentication fails.
  Future<String> authenticateWithCredentials(String email, String password) async {
    final authRequest = AuthenticationRequestDto(
      email: email,
      password: password,
    );
    
    final response = await _sendLoginRequest(authRequest);
    return _extractTokenFromResponse(response);
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  /// Retrieves the stored credentials from SecretCredentialsService.
  /// Throws an [AuthenticationException] if no credentials are stored.
  Future<AuthenticationRequestDto> _getStoredCredentials() async {
    final hasCredentials = await _credentialsService.hasCredentials();
    if (!hasCredentials) {
      throw AuthenticationException(
        'No stored credentials found. Please configure credentials first.',
        AuthenticationErrorType.noCredentials,
      );
    }

    final email = await _credentialsService.getStoredEmail();
    // Note: We need to add a method to get the password
    final password = await _credentialsService.getStoredPassword();

    if (email == null || password == null) {
      throw AuthenticationException(
        'Stored credentials are incomplete.',
        AuthenticationErrorType.noCredentials,
      );
    }

    return AuthenticationRequestDto(email: email, password: password);
  }
  /// Sends the login request to the backend API.
  /// Returns the HTTP response.
  Future<http.Response> _sendLoginRequest(AuthenticationRequestDto authRequest) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$_loginEndpoint');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: authRequest.toJson(),
      );
      
      return response;
    } catch (e) {
      throw AuthenticationException(
        'Network error: Unable to connect to the server. $e',
        AuthenticationErrorType.networkError,
      );
    }
  }

  /// Extracts the JWT token from the login response.
  /// Throws an [AuthenticationException] if the response indicates an error.
  String _extractTokenFromResponse(http.Response response) {
    // Check for successful response
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final jsonResponse = jsonDecode(response.body);
        
        // Try common token field names
        // TODO: Adjust based on your actual backend response structure
        final token = jsonResponse['token'] ?? 
                      jsonResponse['access_token'] ?? 
                      jsonResponse['jwt'] ??
                      jsonResponse['accessToken'];
        
        if (token != null && token.toString().isNotEmpty) {
          return token.toString();
        }
        
        // If the response body is the token itself (just a string)
        if (response.body.isNotEmpty && !response.body.startsWith('{')) {
          return response.body;
        }
        
        throw AuthenticationException(
          'Token not found in response. Response: ${response.body}',
          AuthenticationErrorType.invalidResponse,
        );
      } catch (e) {
        if (e is AuthenticationException) rethrow;
        throw AuthenticationException(
          'Failed to parse login response: $e',
          AuthenticationErrorType.invalidResponse,
        );
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthenticationException(
        'Invalid credentials. Please check your email and password.',
        AuthenticationErrorType.invalidCredentials,
      );
    } else if (response.statusCode >= 500) {
      throw AuthenticationException(
        'Server error (${response.statusCode}). Please try again later.',
        AuthenticationErrorType.serverError,
      );
    } else {
      throw AuthenticationException(
        'Authentication failed with status ${response.statusCode}: ${response.body}',
        AuthenticationErrorType.unknownError,
      );
    }
  }
}

// ============================================================
// CUSTOM EXCEPTIONS
// ============================================================

/// Types of authentication errors that can occur
enum AuthenticationErrorType {
  noCredentials,
  invalidCredentials,
  networkError,
  serverError,
  invalidResponse,
  unknownError,
}

/// Custom exception for authentication errors
class AuthenticationException implements Exception {
  final String message;
  final AuthenticationErrorType type;

  AuthenticationException(this.message, this.type);

  @override
  String toString() => 'AuthenticationException: $message (type: $type)';
}
