import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/user_api.dart';
import '../../models/api_response.dart';
import '../../services/auth_service.dart';
import 'associated_profiles_page.dart';

class AddInfluencerPage extends StatefulWidget {
  final Function(AssociatedProfile) onSave;

  const AddInfluencerPage({super.key, required this.onSave});

  @override
  State<AddInfluencerPage> createState() => _AddInfluencerPageState();
}

class _AddInfluencerPageState extends State<AddInfluencerPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailValidationFormKey = GlobalKey<FormState>();
  final _emailValidationController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _prefixController = TextEditingController(text: '+593');
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _emailValidated = false;
  bool _isValidatingEmail = false;
  String? _influencerId; // ID del influencer si existe

  @override
  void dispose() {
    _emailValidationController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _prefixController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _validateEmail() async {
    if (!_emailValidationFormKey.currentState!.validate()) return;

    setState(() {
      _isValidatingEmail = true;
    });

    try {
      final email = _emailValidationController.text.trim();

      // Buscar influencer por email
      final apiResponse = await UserApi.searchInfluencer(email: email);

      if (mounted) {
        setState(() {
          _isValidatingEmail = false;
        });

        if (apiResponse.success && apiResponse.data != null) {
          // Si se encontró el influencer, llenar los campos
          final data = apiResponse.data as Map<String, dynamic>;
          _influencerId = data['ID'] as String?;

          // Llenar los campos del formulario
          _nameController.text = data['NAME'] as String? ?? '';
          _lastNameController.text = data['LASTNAME'] as String? ?? '';
          _idController.text = data['CARD_ID'] as String? ?? '';
          _emailController.text = data['EMAIL'] as String? ?? email;

          // Procesar teléfono (separar prefijo y número)
          final phone = data['PHONE'] as String? ?? '';
          if (phone.isNotEmpty) {
            if (phone.startsWith('+593')) {
              _prefixController.text = '+593';
              _phoneController.text = phone.substring(4);
            } else if (phone.startsWith('+')) {
              // Otro prefijo, intentar extraer los primeros 4 caracteres
              if (phone.length > 4) {
                _prefixController.text = phone.substring(0, 4);
                _phoneController.text = phone.substring(4);
              } else {
                _prefixController.text = phone;
                _phoneController.text = '';
              }
            } else {
              // Si no tiene prefijo, usar el prefijo por defecto
              _phoneController.text = phone;
            }
          }

          // Procesar fecha de nacimiento
          final birthDateStr = data['BIRTH_DATE'] as String?;
          if (birthDateStr != null && birthDateStr.isNotEmpty) {
            try {
              final birthDate = DateTime.parse(birthDateStr);
              _selectedDate = birthDate;
              _dateController.text = _formatDate(birthDate);
            } catch (e) {
              // Error al parsear fecha, ignorar
            }
          }
        } else {
          // Si no se encontró, solo establecer el email
          _influencerId = null;
        }

        setState(() {
          _emailValidated = true;
          _emailController.text = email;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingEmail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al validar el correo: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDate ?? DateTime(now.year - 18, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: AppColors.textPrimary,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('es', 'ES'),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await AuthService.instance.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la información del usuario'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Preparar datos para el API
      final influencerData = {
        'name': _nameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'card_id': _idController.text.trim(),
        'email': _emailController.text.trim(),
        'phone':
            '${_prefixController.text.trim()}${_phoneController.text.trim()}',
        'birth_date': _selectedDate?.toIso8601String().split(
          'T',
        )[0], // Formato YYYY-MM-DD
      };

      ApiResponse<Map<String, dynamic>> apiResponse;

      if (_influencerId != null && _influencerId!.isNotEmpty) {
        // Si existe el influencer, actualizar
        final updateData = Map<String, dynamic>.from(influencerData);
        updateData['access'] = 'SI';
        updateData['roleId'] =
            3; // Asumimos que el roleId es 3 para influencers

        apiResponse = await UserApi.updateInfluencer(
          userId: _influencerId!,
          influencerData: updateData,
        );

        // Si la actualización fue exitosa, asociar el influencer al manager
        if (apiResponse.success) {
          final associateResponse = await UserApi.associateInfluencer(
            influencerId: _influencerId!,
            notes: 'Reactivacion de usuario',
          );
        }
      } else {
        // Si no existe, crear nuevo
        apiResponse = await UserApi.addInfluencer(influencerData);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (apiResponse.success) {
          widget.onSave(
            AssociatedProfile(
              id: 0,
              managerId: currentUser.id,
              influencerId: '',
              status: 'pending',
              nombre: _nameController.text.trim(),
              apellido: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
            ),
          );
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al agregar el influencer',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        onComplete: () {
          Navigator.pop(context); // Cerrar diálogo
          Navigator.pop(context); // Cerrar página
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si el email no ha sido validado, mostrar solo el formulario de validación
    if (!_emailValidated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Asociar influenciador',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: Form(
          key: _emailValidationFormKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailValidationController,
                    style: const TextStyle(
                      fontFamily: 'ShellBook',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Dirección de correo',
                      border: OutlineInputBorder(),
                      hintText: 'ejemplo@correo.com',
                      hintStyle: const TextStyle(
                        fontFamily: 'ShellBook',
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _validateEmail(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el correo';
                      }
                      if (!RegExp(r'^.+@.+\..+$').hasMatch(value.trim())) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isValidatingEmail ? null : _validateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isValidatingEmail
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textPrimary,
                                ),
                              ),
                            )
                          : const Text(
                              'Validar',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellHeavy',
                                color: AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Si el email ya fue validado, mostrar el formulario completo
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Asociar influenciador',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idController,
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'N° de identificación',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa la identificación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Dirección de correo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el correo';
                        }
                        if (!RegExp(r'^.+@.+\..+$').hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _prefixController,
                            style: const TextStyle(
                              fontFamily: 'ShellBook',
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Prefijo',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(
                              fontFamily: 'ShellBook',
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Número de teléfono',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el número';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (_) {
                            if (_selectedDate == null) {
                              return 'Selecciona la fecha de nacimiento';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Botón fijo al final
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ShellHeavy',
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _SuccessDialog({required this.onComplete});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de sobre
                Icon(Icons.mail_outline, size: 80, color: AppColors.secondary),
                const SizedBox(height: 24),
                // Mensaje
                const Text(
                  'Invitación enviada al correo del influenciador para su aceptación.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Barra de progreso animada pegada al borde
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _animation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
