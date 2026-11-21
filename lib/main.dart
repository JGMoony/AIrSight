import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_feedback_service.dart';
import 'services/haptic_service.dart';
import 'services/text_scale_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/gemini_service.dart';

Future<void> main() async {
  // Asegura la comunicación con el motor nativo de Flutter antes de inicializar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los servicios de Firebase con la configuración generada para cada plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa la configuración de escala de texto accesible
  unawaited(TextScaleService.init());

  // Inicializa la configuración de retroalimentación háptica accesible
  unawaited(HapticService.init());

  // Sube y sincroniza el catálogo inicial del glosario A1 en Firestore si 'glosario_a1' está vacía
  unawaited(FirestoreService.instance.subirGlosarioInicial());

  // Inspecciona y muestra en consola los modelos activos de Google AI Studio para la API Key
  unawaited(GeminiService.instance.inspeccionarModelosDisponibles());

  runApp(const AirSightApp());
}

class AirSightApp extends StatelessWidget {
  const AirSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: TextScaleService.textScaleNotifier,
      builder: (context, scale, child) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'Air Sight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          builder: (context, widgetChild) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: widgetChild ?? const SizedBox.shrink(),
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}