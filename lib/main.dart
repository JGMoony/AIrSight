import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/auth_feedback_service.dart';
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
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Air Sight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const AuthGate(),
    );
  }
}