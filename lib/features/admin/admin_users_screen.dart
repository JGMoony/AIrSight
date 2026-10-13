import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

/// Pantalla interactiva para la administración de usuarios y asignación de roles.
/// Soporta:
/// - Opción A: Búsqueda de usuarios por correo electrónico (.where('email', isEqualTo: ...)).
/// - Opción B: Lista en tiempo real de usuarios registrados con selector interactivo
///   de rol (Estudiante / Administrador del Sistema).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  String _searchFilter = '';
  bool _isSearchingRemote = false;
  UserModel? _remoteSearchResult;
  String? _remoteSearchMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  /// Búsqueda puntual en Firestore por correo electrónico exacto (Opción A)
  Future<void> _searchUserByEmailRemote() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _remoteSearchResult = null;
        _remoteSearchMessage = null;
      });
      return;
    }

    setState(() {
      _isSearchingRemote = true;
      _remoteSearchResult = null;
      _remoteSearchMessage = null;
    });

    try {
      final user = await FirestoreService.instance.getUserByEmail(query);
      if (!mounted) return;

      setState(() {
        _isSearchingRemote = false;
        if (user != null) {
          _remoteSearchResult = user;
          _remoteSearchMessage = null;
        } else {
          _remoteSearchMessage = 'No se encontró ningún usuario con el correo: $query';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearchingRemote = false;
        _remoteSearchMessage = 'Error al consultar Firestore: $e';
      });
    }
  }

  /// Actualiza el rol del usuario con confirmación de seguridad para la cuenta propia
  Future<void> _updateRole(UserModel user, String newRole) async {
    if (user.canonicalRole == newRole) return;

    final currentUid = _authService.currentUser?.uid;
    final isSelf = user.uid == currentUid;

    if (isSelf && newRole == 'estudiante') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Revocar permisos propios'),
            content: const Text(
              'Estás a punto de cambiar tu propio rol a Estudiante. '
              'Perderás acceso inmediato a este panel de administración. ¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, revocar'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirestoreService.instance.setUserRole(
        userId: user.uid,
        role: newRole,
      );

      final label = newRole == 'administrador'
          ? 'Administrador del Sistema'
          : 'Estudiante';

      final msg = 'Rol de ${user.nombre.isNotEmpty ? user.nombre : user.email} actualizado a $label.';

      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      await _ttsService.speakSpanish(msg);

      if (_remoteSearchResult != null && _remoteSearchResult!.uid == user.uid) {
        setState(() {
          _remoteSearchResult = _remoteSearchResult!.copyWith(rol: newRole);
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al actualizar rol: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios y Roles'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA DE BÚSQUEDA POR CORREO (Opción A)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por email (ej. alumno@mail.com)',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchFilter = val.trim().toLowerCase();
                              if (_searchFilter.isEmpty) {
                                _remoteSearchResult = null;
                                _remoteSearchMessage = null;
                              }
                            });
                          },
                          onSubmitted: (_) => _searchUserByEmailRemote(),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchFilter = '';
                              _remoteSearchResult = null;
                              _remoteSearchMessage = null;
                            });
                          },
                        ),
                      FilledButton.tonal(
                        onPressed: _isSearchingRemote ? null : _searchUserByEmailRemote,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSearchingRemote
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Buscar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Resultado remoto específico si se realizó búsqueda por correo
            if (_remoteSearchMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Text(
                  _remoteSearchMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),

            // LISTA INTERACTIVA EN TIEMPO REAL (Opción B)
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: FirestoreService.instance.streamAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error al cargar lista de usuarios: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final allUsers = snapshot.data ?? [];

                  // Filtrado local en vivo si el admin escribió en el buscador
                  final filteredUsers = _searchFilter.isEmpty
                      ? allUsers
                      : allUsers.where((u) {
                          final matchEmail = u.email.toLowerCase().contains(_searchFilter);
                          final matchName = u.nombre.toLowerCase().contains(_searchFilter);
                          return matchEmail || matchName;
                        }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchFilter.isEmpty
                                  ? 'No hay usuarios registrados en la colección "users"'
                                  : 'No se encontraron usuarios que coincidan con "$_searchFilter"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isAdmin = user.isAdmin;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isAdmin
                                        ? const Color(0xFF3F51B5).withValues(alpha: 0.15)
                                        : AppTheme.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.school_rounded,
                                      color: isAdmin
                                          ? const Color(0xFF3F51B5)
                                          : AppTheme.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nombre.isNotEmpty
                                              ? user.nombre
                                              : 'Sin nombre registrado',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          user.email.isNotEmpty
                                              ? user.email
                                              : 'Sin correo',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? const Color(0xFF3F51B5).withValues(alpha: 0.12)
                                          : Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAdmin
                                              ? Icons.verified_user_rounded
                                              : Icons.school_rounded,
                                          size: 15,
                                          color: isAdmin
                                              ? const Color(0xFF3F51B5)
                                              : Colors.green.shade800,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          user.roleLabel,
                                          style: TextStyle(
                                            color: isAdmin
                                                ? const Color(0xFF3F51B5)
                                                : Colors.green.shade800,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selector interactivo de rol (Estudiante / Administrador)
                                  DropdownButtonHideUnderline(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: DropdownButton<String>(
                                        value: user.canonicalRole,
                                        isDense: true,
                                        borderRadius: BorderRadius.circular(14),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'estudiante',
                                            child: Text(
                                              'Estudiante',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'administrador',
                                            child: Text(
                                              'Administrador',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (newRole) {
                                          if (newRole != null) {
                                            _updateRole(user, newRole);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
