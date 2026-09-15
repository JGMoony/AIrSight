import 'package:flutter/services.dart';

/// Servicio centralizado de retroalimentación háptica accesible (WCAG 2.2 AA).
/// Proporciona patrones táctiles diferenciados para confirmar acciones,
/// aciertos y errores en la interfaz sin depender exclusivamente del canal auditivo.
class HapticService {
  HapticService._();

  /// Pulsación ligera para selección, navegación o taps en controles estándar.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Patrón de éxito (respuesta correcta): dos pulsos táctiles rápidos sucesivos.
  static Future<void> success() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Patrón de error (respuesta incorrecta o fallo): patrón de alerta pesado y pronunciado.
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
