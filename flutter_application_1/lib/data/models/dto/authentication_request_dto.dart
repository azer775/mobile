import 'dart:convert';

/// DTO for authentication request to backend
/// 
/// This class represents the request body sent to the login endpoint
/// to obtain a JWT token.
class AuthenticationRequestDto {
  final String email;
  final String password;

  AuthenticationRequestDto({
    required this.email,
    required this.password,
  });

  /// Convert to Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create from Map
  factory AuthenticationRequestDto.fromMap(Map<String, dynamic> map) {
    return AuthenticationRequestDto(
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  /// Create from JSON string
  factory AuthenticationRequestDto.fromJson(String jsonString) {
    return AuthenticationRequestDto.fromMap(jsonDecode(jsonString));
  }

  @override
  String toString() => 'AuthenticationRequestDto(email: $email)';
}
