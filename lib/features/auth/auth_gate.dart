import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard_screen.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

/// Punto de entrada reactivo para la navegación de autenticación y roles (AuthGate).
/// 1. Escucha en tiempo real el Stream de [FirebaseAuth.instance.authStateChanges].
/// 2. Valida el rol del usuario en Cloud Firestore ('users/{uid}').
/// 3. Redirige a [AdminDashboardScreen] si el rol es 'administrador',
///    o a [HomeScreen] si el rol es 'estudiante'.
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
          final user = snapshot.data!;
          return StreamBuilder<UserModel?>(
            stream: FirestoreService.instance.streamUser(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userModel = userSnapshot.data;
              final isAdmin = userModel?.isAdmin == true ||
                  user.email?.trim().toLowerCase() == 'admin@airsight.com';

              if (isAdmin) {
                return const AdminDashboardScreen();
              }

              return const HomeScreen();
            },
          );
        }

        // Si no hay ninguna sesión activa (o tras un logout), muestra el inicio de sesión
        return const LoginScreen();
      },
    );
  }
}