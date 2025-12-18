import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/auth_api.dart';
import 'login_page.dart';
import 'verify_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();

      final apiResponse = await AuthApi.requestPasswordReset(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (apiResponse.success) {
          // Extraer el token y expiresIn de la respuesta
          String? token;
          String? expiresIn;
          if (apiResponse.data != null && apiResponse.data is Map) {
            final data = apiResponse.data as Map<String, dynamic>;
            token = data['token'] as String?;
            expiresIn = data['expiresIn'] as String?;
          }

          if (token != null && token.isNotEmpty) {
            // Navegar a la página de verificación de código con el token y expiresIn
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VerifyCodePage(
                  email: email,
                  token: token!,
                  expiresIn: expiresIn ?? '10 minutes',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se recibió el token de verificación'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al solicitar el restablecimiento de contraseña',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_person_outlined,
                          size: 50,
                          color: AppColors.textPrimary,
                        ),

                        const SizedBox(height: 32),

                        // Título
                        const Text(
                          '¿Tienes problemas para iniciar sesión?',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ShellHeavy',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Texto instructivo
                        const Text(
                          'Introduce tu correo electrónico y te enviaremos un código de verificación.',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ShellBook',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Campo de correo electrónico
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'Correo electrónico',
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
                              return 'Por favor ingresa tu correo electrónico';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Botón enviar código de verificación
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textPrimary,
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
                                    'Enviar código de verificación',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'ShellHeavy',
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Enlace volver al inicio de sesión
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Volver al inicio de sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'ShellBook',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
