import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';

/// HTTP Client for API calls
class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Map<String, String> _defaultHeaders;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    Map<String, String>? defaultHeaders,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _defaultHeaders = defaultHeaders ??
            {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };

  /// Set authorization token
  void setAuthToken(String token) {
    _defaultHeaders['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token
  void clearAuthToken() {
    _defaultHeaders.remove('Authorization');
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client.get(
        uri,
        headers: {..._defaultHeaders, ...?headers},
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection');
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client.post(
        uri,
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection');
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client.put(
        uri,
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection');
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client.patch(
        uri,
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection');
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client.delete(
        uri,
        headers: {..._defaultHeaders, ...?headers},
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection');
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters:
            queryParams.map((key, value) => MapEntry(key, value.toString())),
      );
    }
    return uri;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ServerException(
        message: 'Unauthorized',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode == 404) {
      throw ServerException(
        message: 'Resource not found',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode >= 500) {
      throw ServerException(
        message: 'Server error',
        statusCode: response.statusCode,
      );
    } else {
      throw ServerException(
        message: 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
