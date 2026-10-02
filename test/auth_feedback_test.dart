import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/core/services/auth_feedback_service.dart';
import 'package:air_sight/core/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de AuthFeedbackService y TtsService Singleton', () {
    test('Verifica textos exactos para inicio de sesión y registro', () {
      expect(
        AuthFeedbackService.welcomeBackMessage,
        equals('Bienvenido de vuelta'),
      );
      expect(
        AuthFeedbackService.registrationSuccessMessage,
        equals('Registro exitoso, bienvenido a Air Sight'),
      );
    });

    test('TtsService implementa un patrón Singleton consistente', () {
      final tts1 = TtsService();
      final tts2 = TtsService.instance;
      final tts3 = TtsService();

      expect(identical(tts1, tts2), isTrue);
      expect(identical(tts1, tts3), isTrue);
    });

    test('rootScaffoldMessengerKey está instanciado globalmente', () {
      expect(rootScaffoldMessengerKey, isNotNull);
    });
  });
}
