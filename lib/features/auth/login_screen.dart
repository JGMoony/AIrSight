import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/services/tts_service.dart';
import '../../data/local_user_storage.dart';
import '../home/home_screen.dart';
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

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ttsService.stop();
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

    setState(() {
      _isLoading = true;
    });

    final success = await LocalUserStorage.login(
      _emailController.text.trim().toLowerCase(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      final user = await LocalUserStorage.getUser();
      if (!mounted) return;

      final greeting = user?.role == 'admin'
          ? 'Bienvenido administrador.'
          : 'Bienvenido ${user?.name ?? "estudiante"}.';

      SemanticsService.announce(greeting, TextDirection.ltr);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      // HU-02 Criterio 2: Alerta auditiva y textual descriptiva
      const errorMessage =
          'Correo o contraseña incorrectos. Por favor verifica tus credenciales.';

      SemanticsService.announce(errorMessage, TextDirection.ltr);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );

      await _ttsService.speakSpanish(errorMessage);
    }
  }

  // HU-02 Criterio 3: Diálogo accesible para restablecimiento de contraseña
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

                Navigator.pop(ctx);
                final sent = await LocalUserStorage.requestPasswordReset(email);

                final message = sent
                    ? 'Se han enviado las instrucciones de restablecimiento a $email.'
                    : 'Si el correo está registrado, recibirás un enlace de recuperación.';

                SemanticsService.announce(message, TextDirection.ltr);
                await _ttsService.speakSpanish(message);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
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

                const SizedBox(height: 40),

                // Campo Correo con Semantics
                Semantics(
                  textField: true,
                  label: 'Correo electrónico',
                  hint: 'Ingresa tu correo registrado',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                    onFieldSubmitted: (_) => _login(),
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
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón Iniciar Sesión
                Semantics(
                  label: 'Botón iniciar sesión',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
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

                const SizedBox(height: 12),

                // Botón Crear Cuenta
                Semantics(
                  label: 'Crear una nueva cuenta',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
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
                    label: const Text('Crear cuenta'),
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