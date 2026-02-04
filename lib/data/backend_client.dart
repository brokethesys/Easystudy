import 'dart:convert';

import 'package:http/http.dart' as http;

const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class BackendClient {
  BackendClient({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? kBackendBaseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<AuthResponse> register({
    required String email,
    required String password,
    Map<String, dynamic>? config,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        if (config != null) 'config': config,
      }),
    );

    return _parseAuthResponse(response);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _parseAuthResponse(response);
  }

  Future<ConfigResponse> getConfig({required String token}) async {
    final uri = Uri.parse('$_baseUrl/config');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _parseConfigResponse(response);
  }

  Future<ConfigResponse> putConfig({
    required String token,
    required Map<String, dynamic> config,
  }) async {
    final uri = Uri.parse('$_baseUrl/config');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'config': config}),
    );

    return _parseConfigResponse(response);
  }

  AuthResponse _parseAuthResponse(http.Response response) {
    final body = _decodeJson(response);
    if (response.statusCode >= 400) {
      throw BackendException(
        message: _extractMessage(body) ?? 'Auth failed',
        statusCode: response.statusCode,
      );
    }

    return AuthResponse(
      accessToken: body['access_token'] as String,
      tokenType: body['token_type'] as String? ?? 'bearer',
      config: body['config'] is Map<String, dynamic>
          ? (body['config'] as Map<String, dynamic>)
          : null,
    );
  }

  ConfigResponse _parseConfigResponse(http.Response response) {
    final body = _decodeJson(response);
    if (response.statusCode >= 400) {
      throw BackendException(
        message: _extractMessage(body) ?? 'Config request failed',
        statusCode: response.statusCode,
      );
    }

    return ConfigResponse(
      config: body['config'] as Map<String, dynamic>,
      updatedAt: body['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw BackendException(
        message: 'Invalid server response',
        statusCode: response.statusCode,
      );
    }
  }

  String? _extractMessage(Map<String, dynamic> body) {
    final detail = body['detail'];
    if (detail is String) return detail;
    return null;
  }
}

class AuthResponse {
  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    this.config,
  });

  final String accessToken;
  final String tokenType;
  final Map<String, dynamic>? config;
}

class ConfigResponse {
  ConfigResponse({required this.config, required this.updatedAt});

  final Map<String, dynamic> config;
  final String updatedAt;
}

class BackendException implements Exception {
  BackendException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'BackendException($statusCode): $message';
}
