import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../glossary/glossary_screen.dart';
import '../home/home_screen.dart';
import 'admin_pilot_metrics_screen.dart';
import 'admin_users_screen.dart';

/// Panel de Control y Perfil exclusivo para el rol de Administrador.
/// Centraliza la gestión de datos, mantenimiento del glosario en Firestore,
/// métricas del piloto pedagógico y asignación de roles.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TtsService _ttsService = TtsService();
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoadingUser = true;
  bool _isSyncingGlossary = false;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    final currentFirebaseUser = _authService.currentUser;
    UserModel? model;

    if (currentFirebaseUser != null) {
      try {
        model = await FirestoreService.instance.getUser(currentFirebaseUser.uid);
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _userModel = model ??
          UserModel(
            id: currentFirebaseUser?.uid ?? 'admin_uid',
            nombre: currentFirebaseUser?.displayName ?? 'Administrador UDEC',
            email: currentFirebaseUser?.email ?? 'admin@airsight.com',
            rol: 'administrador',
            fechaRegistro: DateTime.now(),
          );
      _isLoadingUser = false;
    });
  }

  /// Acción de mantenimiento: sincroniza y puebla el catálogo A1 en Firestore
  Future<void> _syncGlossaryToFirestore() async {
    if (_isSyncingGlossary) return;
    setState(() => _isSyncingGlossary = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprobando y sincronizando glosario A1 en Cloud Firestore...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final total = await FirestoreService.instance.subirGlosarioInicial(force: false);
      if (!mounted) return;

      final message = total > 0
          ? '¡Éxito! Se cargaron $total palabras a la colección "glosario_a1".'
          : 'La colección "glosario_a1" ya se encuentra sincronizada con las 102 palabras.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      await _ttsService.speakSpanish(message);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = 'Error al sincronizar glosario en Firestore: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
      await _ttsService.speakSpanish('Ocurrió un error al sincronizar con la base de datos.');
    } finally {
      if (mounted) setState(() => _isSyncingGlossary = false);
    }
  }



  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _isLoadingUser
        ? 'Cargando perfil...'
        : (_userModel?.nombre.isNotEmpty == true
            ? _userModel!.nombre
            : 'Administrador UDEC');
    final displayEmail = _isLoadingUser
        ? '...'
        : (_userModel?.email.isNotEmpty == true
            ? _userModel!.email
            : 'admin@airsight.com');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // a) INFORMACIÓN DEL PERFIL DEL ADMINISTRADOR
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayEmail,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: Color(0xFF3F51B5),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Administrador del Sistema',
                            style: TextStyle(
                              color: Color(0xFF3F51B5),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // b) ZONA DE MANTENIMIENTO DE DATOS
            const Text(
              'Mantenimiento de Base de Datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: Colors.teal,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Glosario A1 en Cloud Firestore',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Colección "glosario_a1" (102 palabras base)',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Sube y verifica la existencia del catálogo pedagógico A1 con traducción, fonética, ejemplos bilingües y etiquetas de visión artificial.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncingGlossary ? null : _syncGlossaryToFirestore,
                        icon: _isSyncingGlossary
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _isSyncingGlossary
                              ? 'Sincronizando...'
                              : 'Sincronizar / Poblar Glosario A1',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // c) ACCIONES ADMINISTRATIVAS (SRS MVP)
            const Text(
              'Acciones Administrativas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Opción 1: Gestión del Catálogo A1 (CRUD)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                ),
                title: const Text(
                  'Gestión del Catálogo A1',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                subtitle: const Text(
                  'Agregar palabras, editar traducciones y administrar términos',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GlossaryScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Opción 2: Métricas Generales del Piloto
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.purple,
                    size: 26,
                  ),
                ),
                title: const Text(
                  'Métricas Generales del Piloto',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                subtitle: const Text(
                  'Consulta consolidada de telemetría y desempeño de estudiantes',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPilotMetricsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Opción 3: Gestión de Roles por Correo o Selección Interactiva
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.amber.shade900,
                    size: 26,
                  ),
                ),
                title: const Text(
                  'Gestión de Roles de Usuario',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                subtitle: const Text(
                  'Buscar por correo o asignar roles en lista interactiva',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUsersScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Opción 4: Previsualizar vista de Estudiante
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.blue,
                    size: 26,
                  ),
                ),
                title: const Text(
                  'Previsualizar Modo Estudiante',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                subtitle: const Text(
                  'Inspeccionar la interfaz de aprendizaje accesible del estudiante',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // d) BOTÓN DE CERRAR SESIÓN
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
