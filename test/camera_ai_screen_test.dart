import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:air_sight/services/tts_service.dart';
import 'package:air_sight/core/theme/app_theme.dart';
import 'package:air_sight/features/camera_ai/camera_ai_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme(),
      home: child,
    );
  }

  group('Módulo de Cámara Accesible (IEEE 830 RF-03, RF-04, RF-05, RNF-01, RNF-02, RNF-03)', () {
    testWidgets('Renderiza visor con bordes redondeados (24 dp) y botón accesible >= 56 dp', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const CameraAiScreen()));
      await tester.pump();

      // 1. Verifica el título de la pantalla
      expect(find.text('Explorar con cámara'), findsOneWidget);

      // 2. Verifica el visor con bordes redondeados de 24 dp (RF-03)
      final scannerTitle = find.text('Escáner Visual A1');
      expect(scannerTitle, findsOneWidget);

      final visorContainerFinder = find.ancestor(
        of: scannerTitle,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(24),
        ),
      );
      expect(visorContainerFinder, findsOneWidget);

      // 3. Verifica el botón principal de captura accesible (>= 56 dp de altura)
      final buttonTextFinder = find.text('Capturar y Analizar');
      expect(buttonTextFinder, findsOneWidget);

      final inkWellFinder = find.ancestor(
        of: buttonTextFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsOneWidget);

      final size = tester.getSize(inkWellFinder);
      expect(size.height, greaterThanOrEqualTo(56.0));

      // 4. Verifica la etiqueta semántica del botón
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label == 'Capturar y reconocer objeto' ||
                w.properties.label == 'Capturar foto para identificar objeto en inglés') &&
            w.properties.button == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('El alias CameraScreen es idéntico a CameraAiScreen', (tester) async {
      const screen = CameraScreen();
      expect(screen, isA<CameraAiScreen>());
    });

    test('TtsService expone speakCameraRecognitionResult para la locución bilingüe de 5 fases', () {
      final tts = TtsService.instance;
      expect(tts.speakCameraRecognitionResult, isNotNull);
    });
  });
}
