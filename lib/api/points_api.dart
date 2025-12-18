import '../api.dart';
import '../models/api_response.dart';

/// Endpoints relacionados con puntos
class PointsApi {
  /// Obtener puntos del usuario actual
  static Future<ApiResponse<Map<String, dynamic>>> getCurrentPoints() async {
    return await ApiConfig.getResponse<Map<String, dynamic>>('/points/current');
  }

  /// Obtener puntos del usuario actual desde /puntos/me
  static Future<ApiResponse<Map<String, dynamic>>> getMyPoints() async {
    return await ApiConfig.getResponse<Map<String, dynamic>>('/puntos/me');
  }

  /// Obtener historial de puntos
  static Future<ApiResponse<Map<String, dynamic>>> getPointsHistory({
    int? page,
    int? limit,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/points/history',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Agregar puntos al usuario
  static Future<ApiResponse<Map<String, dynamic>>> addPoints({
    required int points,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = {
      'points': points,
      'reason': reason,
      if (additionalData != null) ...additionalData,
    };

    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/points/add',
      body: body,
    );
  }

  /// Canjear puntos
  static Future<ApiResponse<Map<String, dynamic>>> redeemPoints({
    required int points,
    required String reason,
  }) async {
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/points/redeem',
      body: {'points': points, 'reason': reason},
    );
  }

  /// Obtener estadísticas de puntos
  static Future<ApiResponse<Map<String, dynamic>>> getPointsStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/points/stats',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Obtener mis canjes
  static Future<ApiResponse<Map<String, dynamic>>> getMyRedemptions() async {
    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/canjes/mis-canjes',
    );
  }

  /// Canjear un producto
  static Future<ApiResponse<Map<String, dynamic>>> redeemProduct({
    required String productId,
    int? addressId,
    String comments = '',
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      'comments': comments,
    };
    
    // Solo agregar addressId si no es null (para vendedores será null)
    if (addressId != null) {
      body['addressId'] = addressId;
    }
    
    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/canjes',
      body: body,
    );
  }
}
