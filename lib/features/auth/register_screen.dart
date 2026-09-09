import 'package:flutter/material.dart';

import '../../data/local_user_storage.dart';
import 'auth_user.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = AuthUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
    );

    final success = await LocalUserStorage.registerUser(user);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Ahora puedes iniciar sesión.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un usuario registrado en este dispositivo.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Pantalla de registro de usuario',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Crear cuenta en AIr Sight',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registra tus datos para guardar tu progreso dentro de la aplicación.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre es demasiado corto';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

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
                    textInputAction: TextInputAction.next,
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
                        return 'Debe tener mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
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
                    onFieldSubmitted: (_) => _register(),
                  ),

                  const SizedBox(height: 24),

                  Semantics(
                    label: 'Botón registrar usuario',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _register,
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

                  const SizedBox(height: 12),

                  Semantics(
                    label: 'Ir a pantalla de inicio de sesión',
                    button: true,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      child: const Text('Ya tengo cuenta'),
                    ),
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