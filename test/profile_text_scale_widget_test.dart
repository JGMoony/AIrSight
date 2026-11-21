import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:air_sight/features/profile/profile_screen.dart';
import 'package:air_sight/services/text_scale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ProfileScreen muestra permanentemente las 4 opciones accesibles de tamaño de texto', (tester) async {
    // Setea un tamaño de pantalla suficientemente alto para ver la tarjeta sin scroll
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificación de presencia del título y las 4 opciones
    expect(find.text('Tamaño de texto de la aplicación'), findsOneWidget);
    expect(find.text('Pequeño (0.9x)'), findsOneWidget);
    expect(find.text('Normal (1.0x)'), findsOneWidget);
    expect(find.text('Grande (1.2x)'), findsOneWidget);
    expect(find.text('Muy grande (1.3x)'), findsOneWidget);

    // 2. Verificación de Semantics
    expect(
      find.bySemanticsLabel('Tamaño Pequeño (0.9x)'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Tamaño Normal (1.0x)'),
      findsOneWidget,
    );

    // 3. Tapping y actualización reactiva
    await tester.tap(find.text('Grande (1.2x)'));
    await tester.pumpAndSettle();

    expect(TextScaleService.currentScale, equals(1.2));

    // Regresar a normal
    await tester.tap(find.text('Normal (1.0x)'));
    await tester.pumpAndSettle();

    expect(TextScaleService.currentScale, equals(1.0));
  });
}
