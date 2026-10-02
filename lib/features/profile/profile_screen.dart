import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_user_storage.dart';
import '../auth/auth_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TtsService _ttsService = TtsService();

  AuthUser? _user;
  bool _isLoadingUser = true;

  bool hapticsEnabled = true;
  double speechRate = 0.45;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final localUser = await LocalUserStorage.getUser();
    final firebaseUser = AuthService().currentUser;

    if (!mounted) return;

    setState(() {
      _user = localUser ??
          (firebaseUser != null
              ? AuthUser(
                  name: firebaseUser.displayName ?? 'Estudiante',
                  email: firebaseUser.email ?? '',
                  password: '',
                  role: 'student',
                )
              : null);
      _isLoadingUser = false;
    });
  }

  Future<void> _logout() async {
    await AuthService().signOut();

    if (!mounted) return;

    // Con AuthGate escuchando authStateChanges(), volver a la raíz
    // conduce automáticamente a LoginScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String get _displayName {
    if (_isLoadingUser) return 'Cargando usuario...';
    return _user?.name ?? 'Estudiante';
  }

  String get _displayEmail {
    if (_isLoadingUser) return 'Cargando información...';
    return _user?.email ?? 'Modo MVP local';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayEmail,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Modo MVP local. En la siguiente fase puede conectarse Firebase Authentication.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accesibilidad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Retroalimentación háptica'),
                      subtitle: const Text(
                        'Vibración para acciones importantes',
                      ),
                      value: hapticsEnabled,
                      onChanged: (value) {
                        setState(() {
                          hapticsEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Velocidad de voz'),
                    Slider(
                      value: speechRate,
                      min: 0.25,
                      max: 0.70,
                      divisions: 9,
                      label: speechRate.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          speechRate = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Probar síntesis de voz',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _ttsService.speakSpanish(
                            'Esta es una prueba de voz para verificar la accesibilidad del aplicativo.',
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Probar voz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Para la versión de tesis, este módulo documenta ajustes básicos de accesibilidad. Más adelante se puede persistir la velocidad de voz y la vibración con SharedPreferences o Firebase.',
                  style: TextStyle(height: 1.35),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Semantics(
              label: 'Cerrar sesión',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}