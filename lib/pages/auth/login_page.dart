import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../services/auth_service.dart';
import 'forgot_password_page.dart';
import 'loading_video_page.dart';

enum LoginStep { email, password, createPassword }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  LoginStep _currentStep = LoginStep.email;
  String? _userId;
  bool _hasPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailValidation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await AuthApi.verifyPassword(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        if (apiResponse.success) {
          // Obtener datos desde data (que contiene hasPassword e id)
          Map<String, dynamic>? responseData;

          // Intentar obtener desde apiResponse.data primero
          if (apiResponse.data != null &&
              apiResponse.data is Map<String, dynamic>) {
            responseData = apiResponse.data as Map<String, dynamic>;
          }
          // Si no está en data, intentar desde rawData['data']
          else if (apiResponse.rawData?['data'] != null) {
            final rawDataValue = apiResponse.rawData!['data'];
            if (rawDataValue is Map<String, dynamic>) {
              responseData = rawDataValue;
            }
          }

          if (responseData != null) {
            _hasPassword = responseData['hasPassword'] as bool? ?? false;
            _userId = responseData['id'] as String?;
          } else {
            // Fallback: intentar obtener desde rawData directamente
            _hasPassword =
                apiResponse.rawData?['hasPassword'] as bool? ?? false;
            _userId = apiResponse.rawData?['id'] as String?;
          }

          // Si no tiene contraseña, necesitamos el userId para crear la contraseña
          if (!_hasPassword && _userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo obtener el ID del usuario'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          setState(() {
            _currentStep = _hasPassword
                ? LoginStep.password
                : LoginStep.createPassword;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al validar el correo',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSavePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await UserApi.updatePassword(
        userId: _userId!,
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (apiResponse.success) {
          // Después de guardar la contraseña, hacer login
          await _handleLogin();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al guardar la contraseña',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar AuthService.login() para centralizar la lógica de login
      final loginResult = await AuthService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (loginResult != null) {
          // Mostrar video de carga antes de navegar
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoadingVideoPage(
                user: loginResult.user,
                hasCompletedOnboarding: loginResult.hasCompletedOnboarding,
              ),
            ),
          );
        } else {
          // Error en el login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenciales incorrectas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error de conexión o excepción
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título
                      const Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'ShellHeavy',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Logo Shell
                      Center(
                        child: Image.asset(
                          'assets/images/brand/1-LOGO-CLUB-SHELL-MAXX2.jpeg',
                          width: 150,
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa tu correo para continuar',
                        style: TextStyle(fontSize: 16, fontFamily: 'ShellBook'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Formulario de login
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Campo de email (siempre visible)
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: _currentStep == LoginStep.email,
                              style: const TextStyle(
                                fontFamily: 'ShellBook',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Correo',
                                hintText: 'Ingresa tu correo',
                                hintStyle: const TextStyle(
                                  fontFamily: 'ShellBook',
                                ),
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu email';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor ingresa un email válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Botón Validar (solo en paso de email)
                            if (_currentStep == LoginStep.email)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleEmailValidation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textPrimary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Continuar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'ShellHeavy',
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                ),
                              ),

                            // Campo de contraseña (si tiene contraseña)
                            if (_currentStep == LoginStep.password) ...[
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontFamily: 'ShellBook',
                                  fontWeight: FontWeight.normal,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  hintText: 'Ingresa tu contraseña',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'ShellBook',
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              // Botón de login
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textPrimary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'ShellHeavy',
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Enlace "¿Olvidaste tu contraseña?"
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],

                            // Campos para crear contraseña (si no tiene contraseña)
                            if (_currentStep == LoginStep.createPassword) ...[
                              const Text(
                                'Crea una contraseña para tu cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontFamily: 'ShellBook',
                                  fontWeight: FontWeight.normal,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  hintText: 'Ingresa tu nueva contraseña',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'ShellBook',
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa una contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(
                                  fontFamily: 'ShellBook',
                                  fontWeight: FontWeight.normal,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Contraseña',
                                  hintText: 'Confirma tu contraseña',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'ShellBook',
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              // Botón Guardar Contraseña
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleSavePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textPrimary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Guardar Contraseña',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: "ShellHeavy",
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                ),
                              ),
                            ],

                            // Botón para volver al paso anterior
                            if (_currentStep != LoginStep.email) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _currentStep = LoginStep.email;
                                          _passwordController.clear();
                                          _confirmPasswordController.clear();
                                          _userId = null;
                                          _hasPassword = false;
                                        });
                                      },
                                child: const Text(
                                  'Volver',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
