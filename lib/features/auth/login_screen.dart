import 'package:flutter/material.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña incorrectos.'),
        ),
      );
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

  Future<void> _goToRegister() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Pantalla de inicio de sesión de AIr Sight',
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

                  TextFormField(
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
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
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

                  const SizedBox(height: 24),

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

                  Semantics(
                    label: 'Crear una nueva cuenta',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _goToRegister,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear cuenta'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Versión MVP local',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}