import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

void main() {
  runApp(const AirSightApp());
}

class AirSightApp extends StatelessWidget {
  const AirSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Sight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const AuthGate(),
    );
  }
}
