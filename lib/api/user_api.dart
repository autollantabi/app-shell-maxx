import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
    final response = await ApiConfig.postResponse<Map<String, dynamic>>(
      '/usuarios/search-influencer',
      body: {'email': email},
    );
    debugPrint('searchInfluencer response: success=${response.success}, message=${response.message}, data=${response.data}, rawData=${response.rawData}');
    return response;
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

  /// Asociar un influencer a un manager. Solo lo usa el vendedor; managerId es obligatorio.
  static Future<ApiResponse<Map<String, dynamic>>> associateInfluencer({
    required String influencerId,
    required String managerId,
    String notes = 'Reactivacion de usuario',
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/manager-influencers',
      body: {
        'influencerId': influencerId,
        'managerId': managerId,
        'notes': notes,
      },
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

  /// Obtener influencers asociados a un manager (por ID de manager)
  /// Para que un vendedor vea los influencers de un manager seleccionado.
  static Future<ApiResponse<dynamic>> getInfluencersByManagerId({
    required String managerId,
  }) async {
    return await ApiConfig.getResponse<dynamic>(
      '/manager-influencers/manager/$managerId/influencers',
    );
  }

  /// Obtener managers asociados a un vendedor
  /// GET /manager-vendedor/vendedor/managers
  static Future<ApiResponse<Map<String, dynamic>>> getVendedorManagers() async {
    final endpoint = '/manager-vendedor/vendedor/managers';
    
    final apiResponse = await ApiConfig.getResponse<Map<String, dynamic>>(
      endpoint,
    );
    debugPrint('apiResponse: ${apiResponse.rawData}');
    
    // Extraer datos de rawData si data es null
    Map<String, dynamic>? extractedData;
    if (apiResponse.rawData != null) {
      try {
        final rawDataMap = apiResponse.rawData as Map<String, dynamic>;
        
        // Intentar obtener 'data' del rawData
        if (rawDataMap.containsKey('data') && rawDataMap['data'] is Map) {
          extractedData = rawDataMap['data'] as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('   ❌ Error al procesar rawData: $e');
      }
    }
    
    // Si data es null pero tenemos extractedData, crear nuevo ApiResponse
    if (apiResponse.data == null && extractedData != null) {
      return ApiResponse<Map<String, dynamic>>(
        success: apiResponse.success,
        message: apiResponse.message,
        data: extractedData,
        rawData: apiResponse.rawData,
      );
    }
    
    return apiResponse;
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
