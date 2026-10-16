import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';
import '../../services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../camera_ai/camera_ai_screen.dart';
import '../glossary/glossary_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../../screens/tutor_voz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Permite reiniciar la bandera de bienvenida al cerrar sesión
  static bool hasAnnouncedWelcome = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAnnounceWelcome();
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _checkAndAnnounceWelcome() async {
    if (HomeScreen.hasAnnouncedWelcome) return;
    HomeScreen.hasAnnouncedWelcome = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String studentName = user.displayName?.trim() ?? '';
    if (studentName.isEmpty) {
      try {
        final profile = await FirestoreService.instance.getUser(user.uid);
        if (profile != null && profile.nombre.trim().isNotEmpty) {
          studentName = profile.nombre.trim();
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (studentName.isNotEmpty) {
      await _ttsService.speakSpanish('Bienvenido de nuevo, $studentName.');
    } else {
      await _ttsService.speakSpanish('Bienvenido de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItemData(
        title: 'Glosario',
        subtitle: 'Explora palabras en inglés con su pronunciación y ejemplos.',
        icon: Icons.menu_book_rounded,
        accentColor: const Color(0xFF6366F1),
        destination: const GlossaryScreen(),
      ),
      _MenuItemData(
        title: 'Tutor por voz',
        subtitle: 'Pregunta cómo se dice o pronuncia cualquier palabra.',
        icon: Icons.record_voice_over_rounded,
        badgeText: 'IA Conversacional',
        accentColor: const Color(0xFF8B5CF6),
        destination: const TutorVozScreen(),
      ),
      _MenuItemData(
        title: 'Prácticas guiadas',
        subtitle: 'Juegos cortos para entrenar tu oído y reforzar lo aprendido.',
        icon: Icons.quiz_rounded,
        badgeText: 'Actividades',
        accentColor: const Color(0xFF10B981),
        destination: const PracticeScreen(),
      ),
      _MenuItemData(
        title: 'Explorar con cámara',
        subtitle: 'Apunta a objetos a tu alrededor para conocer su nombre en inglés.',
        icon: Icons.camera_alt_rounded,
        badgeText: 'Visión IA',
        accentColor: const Color(0xFF06B6D4),
        destination: const CameraAiScreen(),
      ),
      _MenuItemData(
        title: 'Mi progreso',
        subtitle: 'Revisa tus logros, aciertos y actividades completadas.',
        icon: Icons.bar_chart_rounded,
        badgeText: 'Estadísticas',
        accentColor: const Color(0xFFF59E0B),
        destination: const ProgressScreen(),
      ),
      _MenuItemData(
        title: 'Perfil y accesibilidad',
        subtitle: 'Ajustes de voz, velocidad y preferencias',
        icon: Icons.person_rounded,
        accentColor: const Color(0xFF64748B),
        destination: const ProfileScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.visibility_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Air Sight'),
          ],
        ),
      ),
      body: SafeArea(
        child: Listener(
          onPointerDown: (_) => _ttsService.stop(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              // Cabecera Principal Accesible con Alto Contraste (WCAG 2.2 AA)
              Semantics(
                label:
                    'Bienvenido a Air Sight. Aprende inglés A1 escuchando tu entorno.',
                container: true,
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 159, 154, 241), // Deep indigo
                        Color.fromARGB(255, 82, 128, 237), // Slate
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprende inglés A1 escuchando tu entorno',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Experiencia multisensorial accesible con inteligencia artificial, audio nativo y retroalimentación háptica.',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF), // Blanco puro para máximo contraste accesible
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

            // Encabezado de sección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Módulos principales',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Text(
                    '6 Módulos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjetas de navegación estilo Lovable / Modern Shadcn
            ...menuItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Semantics(
                    button: true,
                    label: '${item.title}. ${item.subtitle}. Toca dos veces para abrir.',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          HapticService.buttonPress();
                          _ttsService.stop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.destination),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Contenedor cuadrado redondeado con fondo de color suave
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: item.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: item.accentColor.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.accentColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (item.badgeText != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.accentColor.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.badgeText!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: item.accentColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
  final Color accentColor;
  final Widget destination;

  _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    required this.accentColor,
    required this.destination,
  });
}
