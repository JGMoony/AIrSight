import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-03 y RNF-01: Pruebas de Accesibilidad de Controles Táctiles y Semántica (WCAG 2.2 AA)', () {
    testWidgets('Botón de captura e identificación por cámara cumple tamaño mínimo (>= 48x48 dp) y etiqueta semántica', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Semantics(
                button: true,
                label: 'Capturar e identificar objeto con cámara',
                hint: 'Doble toque para tomar la fotografía y enviar a reconocimiento por inteligencia artificial',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 64),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  onPressed: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Identificar objeto',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verificación de tamaño físico >= 48x48 dp
      final Finder buttonFinder = find.byType(ElevatedButton);
      final Size buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Verificación de nodo semántico accesible para lectores de pantalla (TalkBack)
      expect(
        find.bySemanticsLabel('Capturar e identificar objeto con cámara'),
        findsOneWidget,
      );

      // Validación automatizada de directrices de accesibilidad de Flutter
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('Botones de opciones de respuesta en práctica gamificada cumplen con 48x48 dp y etiquetado', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Opción 1: Manzana',
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(220, 52),
                      ),
                      onPressed: () {},
                      child: const Text('Apple - Manzana'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Opción 2: Lápiz',
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(220, 52),
                      ),
                      onPressed: () {},
                      child: const Text('Pencil - Lápiz'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsNWidgets(2));

      for (final element in tester.widgetList<ElevatedButton>(buttons)) {
        final finder = find.byWidget(element);
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));
      }

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('Botón de locución auditiva y micrófono del tutor cumple con área táctil accesible', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Semantics(
                button: true,
                label: 'Hablar con el tutor de voz',
                child: IconButton(
                  iconSize: 36,
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 56,
                  ),
                  tooltip: 'Hablar con el tutor de voz',
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final Finder iconButtonFinder = find.byType(IconButton);
      final Size size = tester.getSize(iconButtonFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });
}
