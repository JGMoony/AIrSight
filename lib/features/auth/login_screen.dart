import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/services/auth_feedback_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/tts_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TtsService _ttsService = TtsService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // No cortamos el motor TTS aquí (_ttsService.stop()) para que el audio
    // de bienvenida continúe reproduciéndose aun cuando AuthGate desmonte esta vista.
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'El formulario contiene errores. Por favor verifica los campos.',
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
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Feedback auditivo y visual global persistente (independiente del ciclo de vida del Widget)
      AuthFeedbackService.showLoginSuccess();

      // AuthGate detecta reactivamente el inicio de sesión y renderiza HomeScreen.
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errorMessage = AuthService.getFriendlyErrorMessage(e);

      SemanticsService.announce(errorMessage, TextDirection.ltr);
      await _ttsService.speakSpanish(errorMessage);

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      const genericError =
          'Error al conectar con el servidor de autenticación. Verifica tu red.';
      SemanticsService.announce(genericError, TextDirection.ltr);
      await _ttsService.speakSpanish(genericError);

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

  Future<void> _loginWithGoogle() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoadingGoogle = true;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        // El usuario canceló la selección de cuenta
        return;
      }

      // Detección automática según metadatos de Google (isNewUser):
      // isNewUser == true  -> 'Registro exitoso, bienvenido a Air Sight'
      // isNewUser == false -> 'Bienvenido de vuelta'
      AuthFeedbackService.showGoogleAuthSuccess(credential);

      // AuthGate detecta automáticamente la sesión y navega a HomeScreen
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errorMessage = AuthService.getFriendlyErrorMessage(e);

      SemanticsService.announce(errorMessage, TextDirection.ltr);
      await _ttsService.speakSpanish(errorMessage);

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      const genericError =
          'No se pudo completar el inicio de sesión con Google. Intenta nuevamente.';
      SemanticsService.announce(genericError, TextDirection.ltr);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(genericError),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  // HU-02 Criterio 3: Diálogo accesible para restablecimiento de contraseña vía Firebase Auth
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa tu correo registrado para recibir las instrucciones de recuperación.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Semantics(
                textField: true,
                label: 'Correo electrónico para restablecimiento',
                hint: 'Ingresa tu correo registrado',
                child: TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty || !emailRegex.hasMatch(email)) {
                  SemanticsService.announce(
                    'Ingresa un correo electrónico válido.',
                    TextDirection.ltr,
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                try {
                  await _authService.sendPasswordResetEmail(email);

                  final message =
                      'Se han enviado las instrucciones de restablecimiento a $email.';
                  SemanticsService.announce(message, TextDirection.ltr);
                  await _ttsService.speakSpanish(message);

                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  final errorMsg = AuthService.getFriendlyErrorMessage(e);
                  SemanticsService.announce(errorMsg, TextDirection.ltr);
                  await _ttsService.speakSpanish(errorMsg);

                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                Icon(
                  Icons.visibility_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(height: 16),

                Text(
                  'AIr Sight',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Aprendizaje accesible de inglés A1 mediante audio e inteligencia artificial.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 36),

                // Campo Correo con Semantics
                Semantics(
                  textField: true,
                  label: 'Correo electrónico',
                  hint: 'Ingresa tu correo registrado',
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
                        return 'Ingresa un correo válido (ej. usuario@correo.com)';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Campo Contraseña con Semantics
                Semantics(
                  textField: true,
                  label: 'Contraseña',
                  hint: 'Ingresa tu contraseña',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
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
                        return 'Ingresa tu contraseña';
                      }
                      if (value.trim().length < 6) {
                        return 'La contraseña debe tener mínimo 6 caracteres';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => isAnyLoading ? null : _login(),
                  ),
                ),

                // Enlace de restablecimiento de contraseña (HU-02 Criterio 3)
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label:
                        '¿Olvidaste tu contraseña? Toca dos veces para solicitar el restablecimiento.',
                    button: true,
                    child: TextButton(
                      onPressed: isAnyLoading ? null : _showForgotPasswordDialog,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón Iniciar Sesión con Correo
                Semantics(
                  label: 'Botón iniciar sesión con correo y contraseña',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: isAnyLoading ? null : _login,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _isLoading ? 'Ingresando...' : 'Iniciar sesión',
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Separador visual y semántico
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

                // Botón Iniciar Sesión con Google
                Semantics(
                  label: 'Iniciar sesión con cuenta de Google',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: isAnyLoading ? null : _loginWithGoogle,
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
                          : 'Continuar con Google',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón Crear Cuenta
                Semantics(
                  label: 'Crear una nueva cuenta de estudiante',
                  button: true,
                  child: TextButton.icon(
                    onPressed: isAnyLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('¿No tienes cuenta? Regístrate aquí'),
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