import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Gestiona el ciclo de vida de la sesión: registro, login, logout y
/// restauración del token guardado en disco al reabrir la app.
class AuthService extends ChangeNotifier {
  AuthService(this._api);

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';

  final ApiService _api;

  AuthStatus status = AuthStatus.unknown;
  String? token;
  String? username;
  String? error;
  bool busy = false;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _api.token = savedToken;
    try {
      final me = await _api.me();
      token = savedToken;
      username = me;
      status = AuthStatus.authenticated;
    } catch (_) {
      // Token vencido o inválido: se limpia y se pide login de nuevo.
      await prefs.remove(_tokenKey);
      await prefs.remove(_usernameKey);
      _api.token = null;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register(String user, String password) =>
      _submit(() => _api.register(user, password));

  Future<bool> login(String user, String password) =>
      _submit(() => _api.login(user, password));

  Future<bool> _submit(Future<AuthResult> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      token = result.token;
      username = result.username;
      _api.token = result.token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.token);
      await prefs.setString(_usernameKey, result.username);

      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Si el backend no responde igual queremos cerrar sesión localmente.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    _api.token = null;
    token = null;
    username = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg;
  }
}
