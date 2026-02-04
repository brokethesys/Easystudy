import 'package:shared_preferences/shared_preferences.dart';

import 'backend_client.dart';
import 'game_state.dart';

class AccountService {
  AccountService({BackendClient? client}) : _client = client ?? BackendClient();

  final BackendClient _client;

  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_tokenKey) ?? '').isNotEmpty;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  Future<AuthResult> register({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final response = await _client.register(
      email: email,
      password: password,
      config: state.toConfigMap(),
    );

    await _storeToken(response.accessToken, email);

    return AuthResult(
      token: response.accessToken,
      configApplied: false,
    );
  }

  Future<AuthResult> login({
    required GameState state,
    required String email,
    required String password,
  }) async {
    final response = await _client.login(email: email, password: password);
    await _storeToken(response.accessToken, email);

    bool applied = false;
    if (response.config != null) {
      await state.applyConfigMap(response.config!);
      applied = true;
    }

    return AuthResult(
      token: response.accessToken,
      configApplied: applied,
    );
  }

  Future<void> syncUp(GameState state) async {
    final token = await _getToken();
    if (token == null) {
      throw const AuthRequiredException();
    }
    await _client.putConfig(token: token, config: state.toConfigMap());
  }

  Future<bool> syncDown(GameState state) async {
    final token = await _getToken();
    if (token == null) {
      throw const AuthRequiredException();
    }
    final response = await _client.getConfig(token: token);
    await state.applyConfigMap(response.config);
    return true;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _storeToken(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
  }
}

class AuthResult {
  AuthResult({required this.token, required this.configApplied});

  final String token;
  final bool configApplied;
}

class AuthRequiredException implements Exception {
  const AuthRequiredException();
}
