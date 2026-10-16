import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio accesible para la configuración y persistencia del tamaño de texto de la aplicación.
class TextScaleService {
  TextScaleService._();

  static const String _prefKey = 'pref_app_text_scale';

  static const double scaleSmall = 0.9;
  static const double scaleNormal = 1.0;
  static const double scaleLarge = 1.2;
  static const double scaleExtraLarge = 1.3;

  static const List<double> availableScales = [
    scaleSmall,
    scaleNormal,
    scaleLarge,
    scaleExtraLarge,
  ];

  static final ValueNotifier<double> textScaleNotifier =
      ValueNotifier<double>(scaleNormal);

  static double get currentScale => textScaleNotifier.value;

  /// Carga la preferencia guardada en SharedPreferences al iniciar la aplicación.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedScale = prefs.getDouble(_prefKey);
      if (savedScale != null) {
        // Encontrar la escala más cercana a las disponibles
        final matched = availableScales.firstWhere(
          (s) => (s - savedScale).abs() < 0.05,
          orElse: () => scaleNormal,
        );
        textScaleNotifier.value = matched;
      }
    } catch (e) {
      debugPrint('TextScaleService: Error al inicializar: $e');
    }
  }

  /// Actualiza la escala global de texto y la persiste en el almacenamiento local.
  static Future<void> setTextScale(double scale) async {
    textScaleNotifier.value = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, scale);
    } catch (e) {
      debugPrint('TextScaleService: Error al guardar escala de texto: $e');
    }
  }

  /// Retorna la etiqueta amigable para la escala dada.
  static String getScaleLabel(double scale) {
    if ((scale - scaleSmall).abs() < 0.05) return 'Pequeño (0.9x)';
    if ((scale - scaleNormal).abs() < 0.05) return 'Normal (1.0x)';
    if ((scale - scaleLarge).abs() < 0.05) return 'Grande (1.2x)';
    if ((scale - scaleExtraLarge).abs() < 0.05) return 'Muy grande (1.3x)';
    return '${scale}x';
  }
}
