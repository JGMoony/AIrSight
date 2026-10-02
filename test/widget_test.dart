import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:air_sight/core/services/auth_feedback_service.dart';

void main() {
  testWidgets('rootScaffoldMessengerKey se enlaza correctamente a MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: const Scaffold(
          body: Text('Test Body'),
        ),
      ),
    );

    expect(find.text('Test Body'), findsOneWidget);
    expect(rootScaffoldMessengerKey.currentState, isNotNull);

    // Valida que el ScaffoldMessenger global emite SnackBars
    rootScaffoldMessengerKey.currentState!.showSnackBar(
      const SnackBar(content: Text('Mensaje de prueba')),
    );
    await tester.pump();

    expect(find.text('Mensaje de prueba'), findsOneWidget);
  });
}
