import 'dart:typed_data';
import '../api.dart';
import '../models/api_response.dart';

/// Endpoints relacionados con usuarios
class UserApi {
  /// Cambiar contraseña del usuario
  static Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/usuarios/change-password',
      body: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Actualizar contraseña de un usuario
  static Future<ApiResponse<Map<String, dynamic>>> updatePassword({
    required String userId,
    required String password,
  }) async {
    return await ApiConfig.patchResponse<Map<String, dynamic>>(
      '/usuarios/$userId/password',
      body: {'password': password},
    );
  }

  /// Obtener dirección del usuario
  static Future<ApiResponse<Map<String, dynamic>>> getUserAddress(
    String userId,
  ) async {
    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/direcciones/user/$userId',
    );
  }

  /// Obtener influencers asociados al manager actual
  static Future<ApiResponse<dynamic>> getMyInfluencers() async {
    return await ApiConfig.getResponse<dynamic>(
      '/manager-influencers/my-influencers',
    );
  }

  /// Agregar un influencer asociado al manager actual
  static Future<ApiResponse<Map<String, dynamic>>> addInfluencer(
    Map<String, dynamic> influencerData,
  ) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/usuarios/influencer',
      body: influencerData,
    );
  }

  /// Buscar influencer por email
  static Future<ApiResponse<Map<String, dynamic>>> searchInfluencer({
    required String email,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/usuarios/search-influencer',
      body: {'email': email},
    );
  }

  /// Actualizar un influencer
  static Future<ApiResponse<Map<String, dynamic>>> updateInfluencer({
    required String userId,
    required Map<String, dynamic> influencerData,
  }) async {
    return await ApiConfig.patchResponse<Map<String, dynamic>>(
      '/usuarios/$userId',
      body: influencerData,
    );
  }

  /// Asociar un influencer al manager actual
  static Future<ApiResponse<Map<String, dynamic>>> associateInfluencer({
    required String influencerId,
    String notes = 'Reactivacion de usuario',
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/manager-influencers',
      body: {'influencerId': influencerId, 'notes': notes},
    );
  }

  /// Eliminar asociación entre manager e influencer
  static Future<ApiResponse<Map<String, dynamic>>> deleteInfluencerAssociation({
    required int associationId,
  }) async {
    return await ApiConfig.deleteResponse<Map<String, dynamic>>(
      '/manager-influencers/$associationId',
    );
  }

  /// Actualizar usuario con imagen de perfil (multipart form data)
  /// PATCH /usuarios/{id}
  static Future<ApiResponse<Map<String, dynamic>>> updateUserWithImage({
    required String userId,
    String? name,
    String? lastname,
    String? cardId,
    String? email,
    String? phone,
    int? roleId,
    String? birthDate,
    Uint8List? perfilImage,
    String? access,
  }) async {
    // Preparar campos del formulario
    final fields = <String, String>{};

    if (name != null) fields['name'] = name;
    if (lastname != null) fields['lastname'] = lastname;
    if (cardId != null) fields['card_id'] = cardId;
    if (email != null) fields['email'] = email;
    if (phone != null) fields['phone'] = phone;
    if (roleId != null) fields['roleId'] = roleId.toString();
    if (birthDate != null) fields['birth_date'] = birthDate;
    if (access != null) fields['access'] = access;

    // Preparar archivos
    final files = <String, Uint8List>{};
    final fileNames = <String, String>{};

    if (perfilImage != null) {
      // El servidor espera el campo 'perfilImage' según la especificación
      // Si no funciona, puede que necesite: 'profileImage', 'perfil_image', 'image', etc.
      files['perfilImage'] = perfilImage;
      fileNames['perfilImage'] = 'profile_image.jpg';
    }


    return await ApiConfig.patchMultipart<Map<String, dynamic>>(
      '/usuarios/$userId',
      fields: fields,
      files: files.isNotEmpty ? files : null,
      fileNames: fileNames.isNotEmpty ? fileNames : null,
    );
  }
}
