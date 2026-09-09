import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_user.dart';

class LocalUserStorage {
  static const String _userKey = 'registered_user';
  static const String _sessionKey = 'active_session';

  /// Registrar usuario local
  static Future<bool> registerUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = jsonEncode(user.toJson());

    await prefs.setString(_userKey, userJson);

    return true;
  }

  /// Iniciar sesión
  static Future<bool> login(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString(_userKey);

    if (userString == null) {
      return false;
    }

    final userMap = jsonDecode(userString);

    final user = AuthUser.fromJson(userMap);

    if (
      user.email == email &&
      user.password == password
    ) {
      await prefs.setBool(_sessionKey, true);

      return true;
    }

    return false;
  }

  /// Obtener usuario registrado
  static Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString(_userKey);

    if (userString == null) {
      return null;
    }

    final userMap = jsonDecode(userString);

    return AuthUser.fromJson(userMap);
  }

  /// Verificar sesión activa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_sessionKey) ?? false;
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_sessionKey, false);
  }

  /// Eliminar usuario local (útil para pruebas)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userKey);
    await prefs.remove(_sessionKey);
  }
}