import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'tts_service.dart';

/// Clave global para el ScaffoldMessenger montado en MaterialApp.
/// Permite mostrar SnackBars accesibles y persistentes a través de transiciones
/// de pantalla, incluso cuando AuthGate desmonta LoginScreen/RegisterScreen
/// para montar HomeScreen.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Servicio centralizado de feedback accesible (Visual SnackBar + Audio TTS)
/// para eventos de autenticación (Login y Registro).
class AuthFeedbackService {
  static const String welcomeBackMessage = 'Bienvenido de vuelta';
  static const String registrationSuccessMessage =
      'Registro exitoso, bienvenido a Air Sight';

  /// Dispara el feedback para inicio de sesión exitoso (recurrente).
  static void showLoginSuccess() {
    _triggerFeedback(welcomeBackMessage);
  }

  /// Dispara el feedback para registro exitoso (nuevo usuario).
  static void showRegisterSuccess() {
    _triggerFeedback(registrationSuccessMessage);
  }

  /// Evalúa los metadatos de Google Sign-In ([UserCredential.additionalUserInfo.isNewUser])
  /// para disparar automáticamente el mensaje y audio correspondiente:
  /// - isNewUser == true -> Registro exitoso
  /// - isNewUser == false -> Inicio de sesión recurrente
  static void showGoogleAuthSuccess(UserCredential credential) {
    final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
    debugPrint(
      '[AuthFeedbackService] Google Sign-In completado. isNewUser: $isNewUser',
    );

    if (isNewUser) {
      showRegisterSuccess();
    } else {
      showLoginSuccess();
    }
  }

  /// Ejecución coordinada de Semantics, TTS y SnackBar flotante global.
  static void _triggerFeedback(String message) {
    debugPrint('[AuthFeedbackService] Disparando feedback: "$message"');

    // 1. Accesibilidad para TalkBack / lectores de pantalla
    SemanticsService.announce(message, TextDirection.ltr);

    // 2. Audio TTS en español (no bloqueante, mediante singleton global)
    TtsService.instance.speakSpanish(message);

    // 3. Notificación visual mediante el ScaffoldMessenger global de MaterialApp.
    // Usamos addPostFrameCallback para asegurar que la pantalla de destino (HomeScreen)
    // esté registrada en el ScaffoldMessenger si se encuentra en medio de una transición.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        debugPrint(
          '[AuthFeedbackService] Advertencia: rootScaffoldMessengerKey.currentState es null',
        );
      }
    });
  }
}
