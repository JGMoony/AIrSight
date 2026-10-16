import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../services/text_scale_service.dart';
import '../../services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local_user_storage.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../auth/auth_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TtsService _ttsService = TtsService.instance;

  AuthUser? _user;
  UserModel? _firestoreUser;
  bool _isLoadingUser = true;

  bool _hapticsEnabled = true;
  bool _soundsEnabled = true;
  double _speechRate = 0.50;
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    _speechRate = _ttsService.currentSpeechRate;
    _soundsEnabled = _ttsService.soundsEnabled;
    _hapticsEnabled = HapticService.isEnabled;
    _textScale = TextScaleService.currentScale;
    _loadUser();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final localUser = await LocalUserStorage.getUser();
    User? firebaseUser;
    try {
      firebaseUser = AuthService().currentUser;
    } catch (_) {}
    UserModel? firestoreModel;

    if (firebaseUser != null) {
      try {
        firestoreModel = await FirestoreService.instance.getUser(firebaseUser.uid);
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _firestoreUser = firestoreModel;
      _user = localUser ??
          (firebaseUser != null
              ? AuthUser(
                  name: firestoreModel?.nombre.isNotEmpty == true
                      ? firestoreModel!.nombre
                      : (firebaseUser.displayName ?? 'Estudiante'),
                  email: firebaseUser.email ?? '',
                  password: '',
                  role: firestoreModel?.rol ?? 'estudiante',
                )
              : null);
      _isLoadingUser = false;
    });
  }

  Future<void> _editNameDialog() async {
    final controller = TextEditingController(text: _displayName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar nombre'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre del estudiante',
                hintText: 'Ingresa tu nombre completo',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El nombre no puede estar vacío';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == _displayName) return;

    final firebaseUser = AuthService().currentUser;
    if (firebaseUser != null) {
      try {
        await firebaseUser.updateDisplayName(newName);
        if (_firestoreUser != null) {
          final updated = _firestoreUser!.copyWith(nombre: newName);
          await FirestoreService.instance.saveUser(updated);
          setState(() {
            _firestoreUser = updated;
          });
        }
      } catch (e) {
        debugPrint('Error actualizando nombre en Firebase: $e');
      }
    }

    if (_user != null) {
      final updatedAuth = AuthUser(
        name: newName,
        email: _user!.email,
        password: _user!.password,
        role: _user!.role,
      );
      await LocalUserStorage.registerUser(updatedAuth);
      setState(() {
        _user = updatedAuth;
      });
    }

    await HapticService.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nombre actualizado a: $newName'),
      ),
    );
  }

  Future<void> _changePasswordDialog() async {
    HapticService.selection();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar mi contraseña'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ingresa una nueva contraseña segura para el acceso a tu cuenta.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPassController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          hintText: 'Mínimo 6 caracteres',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Repite la contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val != newPassController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final newPass = newPassController.text.trim();
                    Navigator.pop(ctx);
                    await _updatePasswordDirectly(newPass);
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePasswordDirectly(String newPass) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay una sesión activa de usuario.');
      }
      await user.updatePassword(newPass);
      await HapticService.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      await HapticService.error();
      if (e.code == 'requires-recent-login') {
        _showRecentLoginRequiredDialog();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      await HapticService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar contraseña: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showRecentLoginRequiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificación requerida'),
        content: const Text(
          'Por seguridad, cambiar tu contraseña requiere haber iniciado sesión recientemente. Puedes solicitar un correo de restablecimiento seguro a tu email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _resetPassword();
            },
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Enviar correo'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un correo electrónico válido asociado para restablecer contraseña.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Text(
            'Se enviará un enlace de restablecimiento seguro a tu correo:\n\n$email\n\n¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await AuthService().sendPasswordResetEmail(email);
      await HapticService.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se ha enviado el correo para restablecer la contraseña a $email.'),
        ),
      );
    } catch (e) {
      await HapticService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo de restablecimiento: $e'),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    HapticService.selection();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Seguro que deseas salir de tu cuenta de AirSight?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();

    if (!mounted) return;

    // Con AuthGate escuchando authStateChanges(), volver a la raíz
    // conduce automáticamente a LoginScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _applySpeechRate(double rate) async {
    HapticService.selection();
    setState(() {
      _speechRate = rate;
    });
    await _ttsService.setSpeechRate(rate);
  }

  Future<void> _applyTextScale(double scale) async {
    HapticService.selection();
    setState(() {
      _textScale = scale;
    });
    await TextScaleService.setTextScale(scale);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Semantics(
                          label: 'Editar nombre del estudiante',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                            onPressed: _editNameDialog,
                            tooltip: 'Editar nombre',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: 'Correo electrónico registrado: $_displayEmail, solo lectura',
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _displayEmail,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const Tooltip(
                            message: 'Campo de solo lectura',
                            child: Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _firestoreUser?.roleLabel ?? 'Estudiante',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
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

            const SizedBox(height: 18),

            // Card 2: Cambiar mi contraseña
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cambiar mi contraseña',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Actualiza tu clave de acceso directamente en la aplicación o solicita un enlace de restablecimiento.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Cambiar mi contraseña en la aplicación',
                      button: true,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _changePasswordDialog,
                        icon: const Icon(Icons.lock_rounded),
                        label: const Text('Cambiar mi contraseña'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: 'Enviar enlace para cambiar contraseña por correo',
                      button: true,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('O solicitar enlace por correo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Card 3: Preferencias de audio y vibración
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferencias de audio y vibración',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Retroalimentación háptica. Vibración para acciones importantes y confirmaciones.',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Retroalimentación háptica'),
                        subtitle: const Text(
                          'Vibración para acciones importantes y confirmaciones',
                        ),
                        value: _hapticsEnabled,
                        onChanged: (value) async {
                          await HapticService.setEnabled(value);
                          setState(() {
                            _hapticsEnabled = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Efectos sonoros pedagógicos. Reproducción de locuciones y avisos audibles.',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Efectos sonoros pedagógicos'),
                        subtitle: const Text(
                          'Reproducción de locuciones y avisos de audio',
                        ),
                        value: _soundsEnabled,
                        onChanged: (value) async {
                          await _ttsService.setSoundsEnabled(value);
                          setState(() {
                            _soundsEnabled = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Velocidad de síntesis de voz',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${(_speechRate * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      label: 'Velocidad de voz al ${(_speechRate * 100).round()} por ciento',
                      hint: 'Desliza para ajustar la rapidez con la que habla el tutor',
                      child: Slider(
                        value: _speechRate,
                        min: 0.40,
                        max: 0.70,
                        divisions: 6,
                        label: '${(_speechRate * 100).round()}%',
                        onChanged: (value) async {
                          await _applySpeechRate(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Selector con valores predeterminados (Lento, Normal, Rápido)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: (_speechRate - 0.40).abs() < 0.02
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: (_speechRate - 0.40).abs() < 0.02
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFCBD5E1),
                                width: (_speechRate - 0.40).abs() < 0.02 ? 2.0 : 1.5,
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () => _applySpeechRate(0.40),
                            child: Text(
                              'Lento (0.4)',
                              style: TextStyle(
                                fontWeight: (_speechRate - 0.40).abs() < 0.02
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: (_speechRate - 0.40).abs() < 0.02
                                    ? const Color(0xFF312E81)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: (_speechRate - 0.50).abs() < 0.02
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: (_speechRate - 0.50).abs() < 0.02
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFCBD5E1),
                                width: (_speechRate - 0.50).abs() < 0.02 ? 2.0 : 1.5,
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () => _applySpeechRate(0.50),
                            child: Text(
                              'Normal (0.5)',
                              style: TextStyle(
                                fontWeight: (_speechRate - 0.50).abs() < 0.02
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: (_speechRate - 0.50).abs() < 0.02
                                    ? const Color(0xFF312E81)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: (_speechRate - 0.60).abs() < 0.02
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: (_speechRate - 0.60).abs() < 0.02
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFCBD5E1),
                                width: (_speechRate - 0.60).abs() < 0.02 ? 2.0 : 1.5,
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () => _applySpeechRate(0.60),
                            child: Text(
                              'Rápido (0.6)',
                              style: TextStyle(
                                fontWeight: (_speechRate - 0.60).abs() < 0.02
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: (_speechRate - 0.60).abs() < 0.02
                                    ? const Color(0xFF312E81)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Probar locución de voz con la velocidad configurada',
                      button: true,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
                          HapticService.selection();
                          await _ttsService.setSpeechRate(_speechRate);
                          await _ttsService.speakSpanish(
                            'Esta es una prueba de voz a velocidad ${(_speechRate * 100).round()} por ciento.',
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Probar locución de voz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Card 4: Tamaño de texto de la aplicación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          color: AppTheme.primary,
                          size: 26,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tamaño de texto de la aplicación',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Personaliza el tamaño de la letra para mejorar la visibilidad y lectura en todas las pantallas.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _buildTextScaleOption('Pequeño (0.9x)', TextScaleService.scaleSmall),
                        _buildTextScaleOption('Normal (1.0x)', TextScaleService.scaleNormal),
                        _buildTextScaleOption('Grande (1.2x)', TextScaleService.scaleLarge),
                        _buildTextScaleOption('Muy grande (1.3x)', TextScaleService.scaleExtraLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Muestra de vista previa del tamaño de texto configurado',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: const Text(
                          'Texto de vista previa: El aprendizaje accesible de inglés con AirSight.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Semantics(
              label: 'Cerrar sesión actual',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
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

  Widget _buildTextScaleOption(String label, double scale) {
    final isSelected = (_textScale - scale).abs() < 0.05;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Tamaño $label',
      hint: 'Toca dos veces para seleccionar este tamaño',
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFEEF2FF)
              : const Color(0xFFF1F5F9),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 2.0 : 1.5,
          ),
          minimumSize: const Size(125, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => _applyTextScale(scale),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF312E81)
                : const Color(0xFF334155),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}