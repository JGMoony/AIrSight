import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:air_sight/screens/tutor_voz_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Accesibilidad e Interfaz de TutorVozScreen', () {
    testWidgets('TutorVozScreen renderiza AppBar, botón central de micrófono y chips de sugerencias',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorVozScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar título
      expect(find.text('Tutor por voz'), findsOneWidget);

      // Verificar cabecera accesible
      expect(find.text('Tutor de Inglés A1 con IA'), findsOneWidget);

      // Verificar botón de micrófono central
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.text('Toca el micrófono para preguntar'), findsOneWidget);

      // Verificar chips de sugerencia accesibles
      expect(find.text('¿Cómo se dice lápiz en inglés?'), findsOneWidget);
      expect(find.text('¿Cómo se dice manzana en inglés?'), findsOneWidget);
      expect(find.text('¿Qué significa computer?'), findsOneWidget);
      expect(find.text('¿Cómo se pronuncia chair?'), findsOneWidget);
    });

    testWidgets('Tapping de sugerencia captura la consulta y procesa la solicitud',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TutorVozScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap en chip de sugerencia
      await tester.tap(find.text('¿Cómo se dice manzana en inglés?'));
      await tester.pumpAndSettle();

      // Debe mostrarse la pregunta capturada en la interfaz
      expect(find.text('"¿Cómo se dice manzana en inglés?"'), findsOneWidget);

      // Verifica que se muestre el mensaje limpio y accesible ante error (WCAG 2.2 AA)
      expect(
        find.text('El tutor presenta alta demanda temporal. Por favor, intenta de nuevo en un momento.'),
        findsOneWidget,
      );
    });
  });
}
