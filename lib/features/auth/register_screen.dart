import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/services/auth_feedback_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/tts_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TtsService _ttsService = TtsService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // No cortamos el motor TTS aquí (_ttsService.stop()) para que el audio
    // de registro continúe reproduciéndose aun cuando esta vista sea desmontada/poppeada.
    super.dispose();
  }

  Future<void> _register() async {
    // Si la validación falla, se anuncia verbalmente a TalkBack
    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'El formulario contiene errores. Por favor revisa los campos señalados.',
        TextDirection.ltr,
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // Criterio HU-01: Registro con asignación de rol de Estudiante
      await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'student',
      );

      // Feedback auditivo y visual global persistente (independiente del ciclo de vida del Widget)
      AuthFeedbackService.showRegisterSuccess();

      // AuthGate detecta reactivamente authStateChanges() y conduce a HomeScreen
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errorMessage = AuthService.getFriendlyErrorMessage(e);

      SemanticsService.announce(errorMessage, TextDirection.ltr);
      _ttsService.speakSpanish(errorMessage);

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al registrar usuario: $e');
      const genericError =
          'No se pudo completar el registro. Verifica tu conexión a internet.';
      SemanticsService.announce(genericError, TextDirection.ltr);
      _ttsService.speakSpanish(genericError);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(genericError),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoadingGoogle = true;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // Usuario canceló la selección de cuenta
        return;
      }

      // Detección automática según metadatos de Google (isNewUser):
      // isNewUser == true  -> 'Registro exitoso, bienvenido a Air Sight'
      // isNewUser == false -> 'Bienvenido de vuelta'
      AuthFeedbackService.showGoogleAuthSuccess(credential);

      // Limpia la pila hacia la raíz para revelar HomeScreen montado por AuthGate
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.getFriendlyErrorMessage(e);
      SemanticsService.announce(msg, TextDirection.ltr);
      _ttsService.speakSpanish(msg);
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error en registro con Google: $e');
      const msg = 'No se pudo completar el registro con Google. Intenta nuevamente.';
      SemanticsService.announce(msg, TextDirection.ltr);
      _ttsService.speakSpanish(msg);
      messenger.showSnackBar(
        const SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isAnyLoading = _isLoading || _isLoadingGoogle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                Text(
                  'Únete a AIr Sight',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Regístrate como estudiante para guardar tu progreso y vocabulario.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 28),

                // Campo Nombre Completo
                Semantics(
                  textField: true,
                  label: 'Nombre completo',
                  hint: 'Ingresa tu nombre completo',
                  child: TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    enabled: !isAnyLoading,
                    decoration: _inputDecoration(
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre completo';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Campo Correo Electrónico
                Semantics(
                  textField: true,
                  label: 'Correo electrónico',
                  hint: 'Ingresa tu correo institucional o personal',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !isAnyLoading,
                    decoration: _inputDecoration(
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Ingresa un correo válido (ej. estudiante@correo.com)';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Campo Contraseña
                Semantics(
                  textField: true,
                  label: 'Contraseña',
                  hint: 'Crea una contraseña segura de mínimo 6 caracteres',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enabled: !isAnyLoading,
                    decoration: _inputDecoration(
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      suffixIcon: Semantics(
                        label: _obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        button: true,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.trim().length < 6) {
                        return 'La contraseña debe tener mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Campo Confirmar Contraseña
                Semantics(
                  textField: true,
                  label: 'Confirmar contraseña',
                  hint: 'Vuelve a escribir tu contraseña exactamente igual',
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    enabled: !isAnyLoading,
                    decoration: _inputDecoration(
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_reset_outlined,
                      suffixIcon: Semantics(
                        label: _obscureConfirmPassword
                            ? 'Mostrar confirmación de contraseña'
                            : 'Ocultar confirmación de contraseña',
                        button: true,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value.trim() != _passwordController.text.trim()) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => isAnyLoading ? null : _register(),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón Registrarme con Correo
                Semantics(
                  label: 'Registrarme. Crea tu cuenta de estudiante.',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: isAnyLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _isLoading ? 'Registrando...' : 'Registrarme',
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Separador
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'O continúa con',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 18),

                // Botón Registrarse con Google
                Semantics(
                  label: 'Registrarse con cuenta de Google',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: isAnyLoading ? null : _registerWithGoogle,
                    icon: _isLoadingGoogle
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata_rounded, size: 30),
                    label: Text(
                      _isLoadingGoogle
                          ? 'Conectando con Google...'
                          : 'Registrarse con Google',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Enlace a Iniciar Sesión
                Semantics(
                  label: 'Ya tengo cuenta. Ir a pantalla de inicio de sesión.',
                  button: true,
                  child: TextButton(
                    onPressed: isAnyLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}