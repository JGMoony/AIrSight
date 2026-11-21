import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Servicio centralizado y robusto de retroalimentación háptica accesible (WCAG 2.2 AA).
/// Utiliza el paquete [Vibration] para activación directa del hardware háptico de Android/iOS
/// con patrones nítidos y diferenciados (acierto, fallo y pulsación), manteniendo fallback
/// automático a [HapticFeedback] del sistema si el hardware no admite patrones personalizados.
class HapticFeedbackService {
  HapticFeedbackService._();

  static final HapticFeedbackService instance = HapticFeedbackService._();

  static const String _prefKey = 'pref_haptics_enabled';
  static bool _enabled = true;
  static bool _initialized = false;
  static bool? _hasVibratorCache;
  static bool? _hasCustomVibrationsCache;

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

      // Pre-verificación silenciosa del hardware de vibración
      _hasVibratorCache = await Vibration.hasVibrator();
      if (_hasVibratorCache == true) {
        _hasCustomVibrationsCache = await Vibration.hasCustomVibrationsSupport();
      }
    } catch (_) {
      _enabled = true;
    }
  }

  /// Activa o desactiva la retroalimentación háptica y persiste el cambio.
  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (_isTest) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  /// Determina si el dispositivo dispone de motor de vibración físico.
  static Future<bool> hasVibrator() async {
    if (_isTest) return false;
    if (_hasVibratorCache != null) return _hasVibratorCache!;
    try {
      _hasVibratorCache = await Vibration.hasVibrator();
      return _hasVibratorCache!;
    } catch (_) {
      return false;
    }
  }

  /// Pulsación de botón interactivo / Selección: pulso táctil firme y nítido (70 ms / heavyImpact).
  static Future<void> selection() async {
    if (!_enabled || _isTest) return;
    try {
      final canVibrate = await hasVibrator();
      if (canVibrate) {
        await Vibration.vibrate(duration: 70, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Pulsación de botones principales, cambios de sección o acciones clave (90 ms / heavyImpact).
  static Future<void> buttonPress() async {
    if (!_enabled || _isTest) return;
    try {
      final canVibrate = await hasVibrator();
      if (canVibrate) {
        await Vibration.vibrate(duration: 90, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Vibración física directa e intensa (140 ms / vibrate).
  static Future<void> vibrate({int duration = 140}) async {
    if (!_enabled || _isTest) return;
    try {
      final canVibrate = await hasVibrator();
      if (canVibrate) {
        await Vibration.vibrate(duration: duration, amplitude: 255);
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Patrón de Éxito / Acierto: Un pulso potente y definido (120 ms / heavyImpact).
  static Future<void> success() async {
    if (!_enabled || _isTest) return;
    try {
      final canVibrate = await hasVibrator();
      if (canVibrate) {
        await Vibration.vibrate(duration: 120, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Patrón de Fallo / Error: Patrón doble de alta atención (vibra 160 ms, pausa 90 ms, vibra 160 ms).
  static Future<void> error() async {
    if (!_enabled || _isTest) return;
    try {
      final canVibrate = await hasVibrator();
      if (canVibrate) {
        _hasCustomVibrationsCache ??= await Vibration.hasCustomVibrationsSupport();
        if (_hasCustomVibrationsCache == true) {
          await Vibration.vibrate(pattern: [0, 160, 90, 160], intensities: [0, 255, 0, 255]);
        } else {
          await Vibration.vibrate(duration: 160, amplitude: 255);
          await Future.delayed(const Duration(milliseconds: 90));
          await Vibration.vibrate(duration: 160, amplitude: 255);
        }
      } else {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 90));
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }
}

/// Alias de compatibilidad total con el código existente.
typedef HapticService = HapticFeedbackService;
