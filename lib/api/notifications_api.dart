import '../api.dart';
import '../models/api_response.dart';

/// Endpoints relacionados con notificaciones
class NotificationsApi {
  /// Obtener notificaciones del usuario autenticado
  /// GET /notificaciones/me
  static Future<ApiResponse<Map<String, dynamic>>> getMyNotifications({
    int limit = 20,
    int offset = 0,
    bool soloNoLeidas = true,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'soloNoLeidas': soloNoLeidas.toString(),
    };

    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/notificaciones/me',
      queryParams: queryParams,
    );
  }

  /// Marcar una notificación como leída
  /// PATCH /notificaciones/{id}/read
  static Future<ApiResponse<Map<String, dynamic>>> markAsRead(int id) async {
    return await ApiConfig.patchResponse<Map<String, dynamic>>(
      '/notificaciones/$id/read',
    );
  }
}
