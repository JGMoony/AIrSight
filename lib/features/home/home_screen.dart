import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../camera_ai/camera_ai_screen.dart';
import '../glossary/glossary_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItemData(
        title: 'Glosario',
        subtitle: 'Consulta vocabulario A1 con audio',
        icon: Icons.menu_book_rounded,
        destination: const GlossaryScreen(),
      ),
      _MenuItemData(
        title: 'Práctica',
        subtitle: 'Escucha y responde microlecciones',
        icon: Icons.quiz_rounded,
        destination: const PracticeScreen(),
      ),
      _MenuItemData(
        title: 'Explorar con cámara',
        subtitle: 'Detecta objetos y asócialos con inglés A1',
        icon: Icons.camera_alt_rounded,
        destination: const CameraAiScreen(),
      ),
      _MenuItemData(
        title: 'Progreso',
        subtitle: 'Revisa palabras, audios y respuestas',
        icon: Icons.bar_chart_rounded,
        destination: const ProgressScreen(),
      ),
      _MenuItemData(
        title: 'Perfil',
        subtitle: 'Accesibilidad y configuración',
        icon: Icons.person_rounded,
        destination: const ProfileScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Sight'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Semantics(
              label: 'Bienvenida a Air Sight. Aplicación accesible para aprender inglés A1 con audio e inteligencia artificial.',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.visibility_rounded, color: Colors.white, size: 42),
                    SizedBox(height: 18),
                    Text(
                      'Aprende inglés A1 escuchando tu entorno',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Glosario, práctica auditiva, cámara y progreso en una experiencia accesible.',
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Módulos principales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...menuItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    button: true,
                    label: '${item.title}. ${item.subtitle}. Toca dos veces para abrir.',
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(item.icon, color: AppTheme.primary, size: 28),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(item.subtitle),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => item.destination),
                          );
                        },
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget destination;

  _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destination,
  });
}
