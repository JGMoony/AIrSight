import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'login_screen.dart';

/// Punto de entrada reactivo para la navegación de autenticación (AuthGate).
/// Escucha en tiempo real el Stream de [FirebaseAuth.instance.authStateChanges]
/// para dirigir al usuario automáticamente a la pantalla correspondiente
/// sin consultar banderas locales estáticas obsoletas.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras Firebase valida el token persistido en el arranque de la app
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si Firebase confirma una sesión de usuario activa y válida
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Si no hay ninguna sesión activa (o tras un logout), muestra el inicio de sesión
        return const LoginScreen();
      },
    );
  }
}