import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado de retroalimentación háptica accesible (WCAG 2.2 AA).
/// Proporciona patrones táctiles diferenciados para confirmar acciones,
/// aciertos y errores en la interfaz, con persistencia local en SharedPreferences.
class HapticService {
  HapticService._();

  static const String _prefKey = 'pref_haptics_enabled';
  static bool _enabled = true;
  static bool _initialized = false;

  static bool get isEnabled => _enabled;

  static bool get _isTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Carga la preferencia de vibración háptica desde SharedPreferences (activa por defecto).
  static Future<void> init() async {
    if (_initialized || _isTest) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
      _initialized = true;
    } catch (_) {
      _enabled = true;
    }
  }

  /// Activa o desactiva la retroalimentación háptica y persiste el cambio
  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (_isTest) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  /// Pulsación ligera para selección, navegación o taps en controles estándar.
  static Future<void> selection() async {
    if (!_enabled || _isTest) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Pulsación media para botones principales, cambio de modo o pulsación de micrófono/cámara.
  static Future<void> buttonPress() async {
    if (!_enabled || _isTest) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Vibración física directa para eventos clave.
  static Future<void> vibrate() async {
    if (!_enabled || _isTest) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Patrón de éxito (respuesta correcta): dos pulsos táctiles rápidos sucesivos.
  static Future<void> success() async {
    if (!_enabled || _isTest) return;
    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 90));
      if (!_enabled || _isTest) return;
      await HapticFeedback.vibrate();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Patrón de error (respuesta incorrecta o fallo): patrón de alerta pesado y pronunciado.
  static Future<void> error() async {
    if (!_enabled || _isTest) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}

