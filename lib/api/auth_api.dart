import '../api.dart';
import '../models/api_response.dart';

/// Endpoints relacionados con autenticación
class AuthApi {
  /// Verificacion de contraseña
  static Future<ApiResponse<Map<String, dynamic>>> verifyPassword({
    required String email,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/pre-login',
      body: {'email': email},
      includeAuth: false,
    );
  }

  /// Iniciar sesión
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/login',
      body: {'email': email, 'password': password},
      includeAuth: false,
    );
  }

  /// Cerrar sesión
  static Future<ApiResponse<Map<String, dynamic>>> logout() async {
    return await ApiConfig.postResponse<Map<String, dynamic>>('/auth/logout');
  }

  /// Registrar nuevo usuario
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (additionalData != null) ...additionalData,
    };

    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/register',
      body: body,
      includeAuth: false,
    );
  }

  /// Solicitar recuperación de contraseña (endpoint antiguo, mantener por compatibilidad)
  static Future<ApiResponse<Map<String, dynamic>>> forgotPassword(
    String email,
  ) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/forgot-password',
      body: {'email': email},
      includeAuth: false,
    );
  }

  /// Solicitar restablecimiento de contraseña
  static Future<ApiResponse<Map<String, dynamic>>> requestPasswordReset({
    required String email,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/password/request-reset',
      body: {'email': email},
      includeAuth: false,
    );
  }

  /// Verificar OTP para restablecimiento de contraseña
  static Future<ApiResponse<String>> verifyOtp({
    required String token,
    required String otp,
  }) async {
    return await ApiConfig.postResponse<String>(
      '/password/verify-otp',
      body: {'token': token, 'otp': otp},
      includeAuth: false,
    );
  }

  /// Restablecer contraseña con resetToken
  static Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/password/reset',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
      includeAuth: false,
    );
  }

  /// Verificar código de verificación
  static Future<ApiResponse<Map<String, dynamic>>> verifyCode({
    required String email,
    required String code,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/verify-code',
      body: {'email': email, 'code': code},
      includeAuth: false,
    );
  }

  /// Refrescar token de autenticación
  static Future<ApiResponse<Map<String, dynamic>>> refreshToken(
    String refreshToken,
  ) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/refresh-token',
      body: {'refreshToken': refreshToken},
      includeAuth: false,
    );
  }

  /// Obtener información del usuario actual
  static Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    return await ApiConfig.getResponse<Map<String, dynamic>>('/auth/me');
  }

  /// Actualizar último login del usuario
  static Future<ApiResponse<Map<String, dynamic>>> updateLastLogin({
    required String userId,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/auth/update-last-login',
      body: {'userId': userId},
    );
  }
}
