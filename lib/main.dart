import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/auth_feedback_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Asegura la comunicación con el motor nativo de Flutter antes de inicializar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los servicios de Firebase con la configuración generada para cada plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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