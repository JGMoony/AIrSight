import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    // Si la validación falla, se anuncia verbalmente a TalkBack
    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'El formulario contiene errores. Por favor revisa los campos señalados.',
        TextDirection.ltr,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Criterio HU-01: Asignación automática del rol exclusivo de Estudiante
    final user = AuthUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
      role: 'student',
    );

    final success = await LocalUserStorage.registerUser(user);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      SemanticsService.announce(
        'Registro exitoso. Redirigiendo a inicio de sesión.',
        TextDirection.ltr,
      );

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
      SemanticsService.announce(
        'Error. Ya existe un usuario registrado en este dispositivo.',
        TextDirection.ltr,
      );

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

    // Expresión regular estándar para validación estricta de correo electrónico
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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
                  'Registra tus datos para guardar tu progreso de inglés A1.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Campo Nombre
                Semantics(
                  textField: true,
                  label: 'Nombre completo',
                  hint: 'Ingresa tu nombre y apellido',
                  child: TextFormField(
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
                        return 'El nombre debe tener al menos 3 caracteres';
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
                  hint: 'Ingresa tu correo, por ejemplo usuario@correo.com',
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
                        return 'Ingresa un formato de correo válido (ej. nombre@dominio.com)';
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
                  hint: 'Mínimo 6 caracteres',
                  child: TextFormField(
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
                  hint: 'Vuelve a escribir la misma contraseña',
                  child: TextFormField(
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
                ),

                const SizedBox(height: 24),

                // Botón Registrarme
                Semantics(
                  label: 'Registrarme. Crea tu cuenta de estudiante.',
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

                // Enlace a Iniciar Sesión
                Semantics(
                  label: 'Ya tengo cuenta. Ir a pantalla de inicio de sesión.',
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
    );
  }
}