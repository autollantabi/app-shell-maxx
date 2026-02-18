import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../api/auth_api.dart';
import '../../api/user_api.dart';
import '../../api.dart';
import '../../contexts/points_provider.dart';
import '../../contexts/products_provider.dart';
import 'associated_profiles_page.dart';
import 'change_password_page.dart';
import 'addresses_page.dart';
import 'help_page.dart';
import 'redeemed_prizes_page.dart';
import 'managers_page.dart';
import '../onboarding/onboarding_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const ProfilePage({super.key, required this.user, this.onUserUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImageBytes;
  late UserModel _currentUser;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserData();
    // Cargar puntos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PointsProvider>().loadPoints();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final apiResponse = await AuthApi.getCurrentUser();

      if (apiResponse.success && mounted) {
        Map<String, dynamic>? userData;

        // Intentar obtener desde apiResponse.data primero
        if (apiResponse.data != null &&
            apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;
          if (data.containsKey('ID') || data.containsKey('id')) {
            userData = data;
          } else if (data.containsKey('usuarioData')) {
            userData = data['usuarioData'] as Map<String, dynamic>?;
          }
        }

        // Si no está en data, intentar desde rawData['data']
        if (userData == null && apiResponse.rawData != null) {
          if (apiResponse.rawData!.containsKey('data')) {
            final data = apiResponse.rawData!['data'];
            if (data is Map<String, dynamic>) {
              if (data.containsKey('ID') || data.containsKey('id')) {
                userData = data;
              } else if (data.containsKey('usuarioData')) {
                userData = data['usuarioData'] as Map<String, dynamic>?;
              }
            }
          } else if (apiResponse.rawData!.containsKey('usuarioData')) {
            userData =
                apiResponse.rawData!['usuarioData'] as Map<String, dynamic>?;
          }
        }

        if (userData != null) {
          final updatedUser = UserModel.fromJson(userData);

          // Guardar usuario actualizado en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_session',
            jsonEncode(updatedUser.toJson()),
          );

          setState(() {
            _currentUser = updatedUser;
          });

          // Notificar al padre que el usuario fue actualizado
          if (widget.onUserUpdated != null) {
            widget.onUserUpdated!(updatedUser);
          }
        }
      }
    } catch (e) {
      // Error al cargar datos del usuario, continuar con el usuario actual
    }
  }

  Future<void> _handleRefresh() async {
    await _loadUserData();
    if (mounted) {
      context.read<PointsProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
          // Header amarillo con información del perfil
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
            child: Column(
              children: [
                // Información del perfil
                Row(
                  children: [
                    // Avatar circular
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(child: _buildProfileImage()),
                          ),
                          // Mostrar indicador de carga solo si está subiendo Y no hay imagen local
                          if (_isUploadingImage && _profileImageBytes == null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (!_isUploadingImage)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _handleEditProfilePhoto(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),

                    // Información del usuario
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          Text(
                            _currentUser.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'ShellHeavy',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID ${_currentUser.cedula ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'ShellBook',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Puntos
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Consumer<PointsProvider>(
                                    builder: (context, pointsProvider, child) {
                                      if (pointsProvider.isLoading) {
                                        return const SizedBox(
                                          width: 40,
                                          height: 20,
                                          child: Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Text(
                                        pointsProvider.availablePoints
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'ShellHeavy',
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    'Puntos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'ShellTHAI',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de opciones del perfil
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Solo mostrar "Mis direcciones" si NO es vendedor
                if (!_currentUser.isVendedorByRole)
                  _buildProfileOption(
                    icon: Icons.location_on_outlined,
                    title: 'Mis direcciones',
                    onTap: () => _handleChangeAddress(context),
                  ),
                _buildProfileOption(
                  icon: Icons.edit_outlined,
                  title: 'Cambiar contraseña',
                  onTap: () => _handleChangePassword(context),
                ),
                // Solo mostrar "Ver Influenciadores" si el usuario es Manager (ROLE_ID = 1)
                if (_currentUser.isManagerByRole)
                  _buildProfileOption(
                    icon: Icons.people_outline,
                    title: 'Ver influenciadores',
                    onTap: () => _handleAssociatedProfiles(context),
                  ),
                // Solo mostrar "Managers" si el usuario es Vendedor (ROLE_ID = 2)
                if (_currentUser.isVendedorByRole)
                  _buildProfileOption(
                    icon: Icons.people_outline,
                    title: 'Managers',
                    onTap: () => _handleManagers(context),
                  ),
                _buildProfileOption(
                  title: 'Premios canjeados',
                  onTap: () => _handleRedeemedPrizes(context),
                  imagePath: 'assets/images/icons/gift.png',
                ),
                _buildProfileOption(
                  icon: Icons.help_outline,
                  title: 'Ayuda',
                  onTap: () => _handleHelp(context),
                ),
                _buildProfileOption(
                  icon: Icons.school_outlined,
                  title: 'Onboarding',
                  onTap: () => _handleShowOnboarding(context),
                ),
                const SizedBox(height: 30),

                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                    child: const Text(
                      'Cerrar Sesión',
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
        ],
        ),
      ),
    );
  }

  /// Construye el widget de imagen de perfil
  Widget _buildProfileImage() {
    // Priorizar imagen local si existe (recién seleccionada)
    if (_profileImageBytes != null) {
      return Image.memory(
        _profileImageBytes!,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
      );
    }

    // Si no hay imagen local, intentar cargar desde la URL del servidor
    if (_currentUser.profileImage != null &&
        _currentUser.profileImage!.isNotEmpty &&
        _currentUser.profileImage!.trim().isNotEmpty) {
      // Limpiar la URL: remover comillas, espacios y caracteres especiales
      String imageUrl = _currentUser.profileImage!
          .trim()
          .replaceAll('"', '') // Remover comillas dobles
          .replaceAll("'", '') // Remover comillas simples
          .replaceAll(' ', ''); // Remover espacios

      // Verificar si ya es una URL completa (http:// o https://)
      final isCompleteUrl = imageUrl.startsWith('http://') || 
                           imageUrl.startsWith('https://');

      // Solo construir la URL si NO es completa (es relativa)
      if (!isCompleteUrl) {
        // Remover barras iniciales si existen
        if (imageUrl.startsWith('/')) {
          imageUrl = imageUrl.substring(1);
        }
        // Construir URL completa solo si es relativa
        final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
        imageUrl = '$baseUrl/${imageUrl.replaceAll('\\', '/')}';
      }

      // Agregar timestamp para evitar caché y forzar la recarga
      final separator = imageUrl.contains('?') ? '&' : '?';
      imageUrl = '$imageUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        cacheWidth: 80, // Especificar ancho para optimización
        cacheHeight: 80, // Especificar alto para optimización
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person, size: 40, color: Colors.grey[600]);
        },
      );
    }

    // Si no hay imagen, mostrar icono por defecto
    return Icon(Icons.person, size: 40, color: Colors.grey[600]);
  }

  Widget _buildProfileOption({
    IconData? icon,
    String? imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon ?? Icons.image,
                              color: AppColors.secondary,
                              size: 20,
                            );
                          },
                        )
                      : Icon(
                          icon ?? Icons.help_outline,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'ShellTHAI',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleEditProfilePhoto(BuildContext context) {
    _showEditPhotoBottomSheet(context);
  }

  void _handleChangeAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressesPage(user: _currentUser),
      ),
    );
  }

  void _handleChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(user: _currentUser),
      ),
    );
  }

  void _handleAssociatedProfiles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssociatedProfilesPage(user: _currentUser),
      ),
    );
  }

  void _handleManagers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagersPage(user: _currentUser),
      ),
    );
  }

  void _handleShowOnboarding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingPage(user: _currentUser),
      ),
    );
  }

  void _handleHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpPage()),
    );
  }

  void _handleRedeemedPrizes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RedeemedPrizesPage()),
    );
  }

  void _showEditPhotoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 
                    MediaQuery.of(sheetContext).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 32,
                child: Stack(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Edita la foto de perfil',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'ShellHeavy',
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: SizedBox(
                          width: 32,
                          height: 32,

                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _handleSelectPhoto(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Seleccionar una foto',
                    style: TextStyle(fontSize: 16, fontFamily: 'ShellHeavy'),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _handleTakePhoto(context);
                },
                child: const Text(
                  'Tomar una foto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSelectPhoto(BuildContext context) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        // Recortar la imagen
        final croppedFile = await _cropImage(File(pickedFile.path));
        
        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          if (!mounted) return;

          // Actualizar UI inmediatamente para mostrar la imagen seleccionada
          setState(() {
            _profileImageBytes = bytes;
          });
          
          // Esperar un frame para asegurar que la UI se actualice antes de iniciar la subida
          await Future.delayed(const Duration(milliseconds: 50));

          // Subir imagen al servidor en segundo plano
          _uploadProfileImage(bytes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleTakePhoto(BuildContext context) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // En iOS la ruta de la cámara puede ser temporal; usar una copia estable para el cropper
        final fileToCrop = await _stableImageFileForCrop(pickedFile.path);
        if (fileToCrop == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo acceder a la imagen capturada'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final croppedFile = await _cropImage(fileToCrop);
        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          if (!mounted) return;

          setState(() {
            _profileImageBytes = bytes;
          });
          await Future.delayed(const Duration(milliseconds: 50));
          _uploadProfileImage(bytes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Copia la imagen a un archivo temporal estable (necesario en iOS para el cropper).
  Future<File?> _stableImageFileForCrop(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      final ext = sourcePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final tempDir = Directory.systemTemp;
      final stableFile = File('${tempDir.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await source.copy(stableFile.path);
      return stableFile;
    } catch (_) {
      return File(sourcePath).existsSync() ? File(sourcePath) : null;
    }
  }

  /// Recorta la imagen usando image_cropper
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar imagen',
            toolbarColor: AppColors.secondary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar imagen',
            aspectRatioLockEnabled: true,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        maxWidth: 800,
        maxHeight: 800,
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      // Si hay error al recortar, devolver la imagen original
      return imageFile;
    }
  }

  /// Sube y guarda la imagen de perfil en el servidor (PATCH /usuarios/{id} multipart).
  /// Se llama tanto al elegir foto de galería como al tomar foto con la cámara.
  Future<void> _uploadProfileImage(Uint8List imageBytes) async {
    if (!mounted) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Parsear nombre completo en name y lastname si es necesario
      final nameParts = _currentUser.name.trim().split(' ');
      final name = nameParts.isNotEmpty ? nameParts.first : _currentUser.name;
      final lastname = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Formatear fecha de nacimiento si existe
      String? birthDateStr;
      if (_currentUser.dateOfBirth != null) {
        birthDateStr = _currentUser.dateOfBirth!.toIso8601String().split(
          'T',
        )[0];
      }

      // Llamar al API para actualizar usuario con imagen
      final apiResponse = await UserApi.updateUserWithImage(
        userId: _currentUser.id,
        name: name,
        lastname: lastname.isNotEmpty ? lastname : null,
        cardId: _currentUser.cedula,
        email: _currentUser.email,
        phone: _currentUser.phone,
        roleId: _currentUser.roleId,
        birthDate: birthDateStr,
        perfilImage: imageBytes,
        // access: null, // Agregar si es necesario
      );

      if (!mounted) return;

      if (apiResponse.success) {
        // La imagen ya se guardó en el servidor vía PATCH multipart; recargar usuario
        // para obtener la URL actualizada y mostrar la foto guardada.
        await _loadUserData();
        if (mounted) {
          setState(() {
            _profileImageBytes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil guardada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al actualizar la foto de perfil',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Limpiar providers antes de hacer logout
      if (context.mounted) {
        final pointsProvider = context.read<PointsProvider>();
        final productsProvider = context.read<ProductsProvider>();

        // Limpiar cachés
        await pointsProvider.clearCache();
        await productsProvider.clearCache();

        // Resetear estado de los providers
        pointsProvider.reset();
        productsProvider.reset();
      }

      // Hacer logout (esto también limpia todos los cachés en SharedPreferences)
      await AuthService.instance.logout();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
