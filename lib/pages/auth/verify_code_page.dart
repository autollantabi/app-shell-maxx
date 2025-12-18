import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/auth_api.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final String token;
  final String expiresIn;

  const VerifyCodePage({
    super.key,
    required this.email,
    required this.token,
    required this.expiresIn,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _canResend = false;
  String _currentExpiresIn = '';

  @override
  void initState() {
    super.initState();
    _currentExpiresIn = widget.expiresIn;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  int _parseExpiresIn(String expiresIn) {
    // Parsear formato como "10 minutes" o "2 minutes"
    final parts = expiresIn.toLowerCase().trim().split(' ');
    if (parts.length >= 2) {
      final value = int.tryParse(parts[0]);
      final unit = parts[1];
      if (value != null) {
        if (unit.startsWith('minute')) {
          return value * 60; // Convertir minutos a segundos
        } else if (unit.startsWith('second')) {
          return value;
        } else if (unit.startsWith('hour')) {
          return value * 3600; // Convertir horas a segundos
        }
      }
    }
    // Default: 10 minutos si no se puede parsear
    return 10 * 60;
  }

  void _startCountdown() {
    // Calcular tiempo inicial basado en expiresIn
    final totalSeconds = _parseExpiresIn(_currentExpiresIn);
    _remainingSeconds = totalSeconds;

    _canResend = false;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final otp = _codeController.text.trim();

      final apiResponse = await AuthApi.verifyOtp(
        token: widget.token,
        otp: otp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (apiResponse.success) {
          // Extraer el resetToken de la respuesta
          String? resetToken;
          if (apiResponse.data != null) {
            // La respuesta puede ser un String directamente o un Map
            if (apiResponse.data is String) {
              resetToken = apiResponse.data as String;
            } else if (apiResponse.data is Map) {
              final data = apiResponse.data as Map<String, dynamic>;
              resetToken =
                  data['resetToken'] as String? ?? data['token'] as String?;
            }
          }

          if (resetToken != null && resetToken.isNotEmpty) {
            // Navegar a la página de cambio de contraseña con el resetToken
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    ResetPasswordPage(resetToken: resetToken!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error: No se recibió el token de restablecimiento',
                ),
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
                    : 'Código inválido',
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

  Future<void> _handleResendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await AuthApi.requestPasswordReset(
        email: widget.email,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (apiResponse.success) {
          // Extraer el nuevo token y expiresIn
          String? newToken;
          String? newExpiresIn;
          if (apiResponse.data != null && apiResponse.data is Map) {
            final data = apiResponse.data as Map<String, dynamic>;
            newToken = data['token'] as String?;
            newExpiresIn = data['expiresIn'] as String?;
          }

          if (newToken != null && newToken.isNotEmpty) {
            // Reiniciar el contador con el nuevo expiresIn
            setState(() {
              _currentExpiresIn = newExpiresIn ?? widget.expiresIn;
            });
            _startCountdown();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código reenviado'),
                backgroundColor: Colors.green,
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
                    : 'Error al reenviar el código',
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
                        // Gráfico de tres círculos con línea
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 50,
                          height: 5,
                          color: AppColors.textPrimary,
                        ),

                        const SizedBox(height: 32),

                        // Título
                        const Text(
                          'Ingresa código de verificación',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ShellHeavy',
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Texto instructivo
                        const Text(
                          'Introduce el código de 6 dígitos que hemos enviado a tu correo.',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ShellBook',
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Campo de código de verificación
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'ShellHeavy',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Código de verificación',
                            hintText: '000000',
                            counterText: '',
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
                              return 'Por favor ingresa el código de verificación';
                            }
                            if (value.length != 6) {
                              return 'El código debe tener 6 dígitos';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Texto para reenviar código con contador
                        _canResend
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Si no recibiste el código. ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : _handleResendCode,
                                    child: Text(
                                      'Vuelve a intentarlo.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isLoading
                                            ? Colors.grey
                                            : AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Text(
                                    'Puedes solicitar un nuevo código en:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                      fontFamily: 'ShellHeavy',
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 32),

                        // Botón validar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerifyCode,
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
                                    'Validar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
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
