import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_user.dart';

class LocalUserStorage {
  static const String _userKey = 'registered_user';
  static const String _sessionKey = 'active_session';

  /// Usuario Administrador predeterminado para pruebas del equipo investigador
  static const AuthUser adminUser = AuthUser(
    name: 'Administrador UDEC',
    email: 'admin@airsight.com',
    password: 'admin123',
    role: 'admin',
  );

  /// Registrar usuario local (Estudiante)
  static Future<bool> registerUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
    return true;
  }

  /// Iniciar sesión (valida Estudiante o Administrador)
  static Future<bool> login(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Validar si es el Administrador
    if (cleanEmail == adminUser.email && cleanPassword == adminUser.password) {
      await prefs.setString(_userKey, jsonEncode(adminUser.toJson()));
      await prefs.setBool(_sessionKey, true);
      return true;
    }

    // 2. Validar contra el usuario registrado
    final userString = prefs.getString(_userKey);
    if (userString == null) {
      return false;
    }

    final userMap = jsonDecode(userString);
    final user = AuthUser.fromJson(userMap);

    if (
      user.email.toLowerCase() == cleanEmail &&
      user.password == cleanPassword
    ) {
      await prefs.setBool(_sessionKey, true);
      return true;
    }

    return false;
  }

  /// Restablecer contraseña accesible (HU-02 Criterio 3)
  static Future<bool> requestPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    if (cleanEmail == adminUser.email) {
      return true;
    }

    final userString = prefs.getString(_userKey);
    if (userString == null) {
      return false;
    }

    final userMap = jsonDecode(userString);
    final user = AuthUser.fromJson(userMap);

    return user.email.toLowerCase() == cleanEmail;
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