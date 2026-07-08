import '../api.dart';
import '../models/api_response.dart';

/// Endpoints relacionados con regalos/productos
class GiftsApi {
  /// Obtener lista de regalos/productos
  static Future<ApiResponse<dynamic>> getGifts({
    int? page,
    int? limit,
    String? category,
    String? search,
    Map<String, String>? filters,
  }) async {
    final queryParams = <String, String>{};

    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      queryParams.addAll(filters);
    }

    return await ApiConfig.getResponse<dynamic>(
      '/productos',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Obtener un regalo/producto por ID
  static Future<ApiResponse<Map<String, dynamic>>> getGiftById(
    String giftId,
  ) async {
    return await ApiConfig.getResponse<Map<String, dynamic>>('/gifts/$giftId');
  }

  /// Obtener un producto por ID (datos frescos, sin caché de lista)
  /// GET /productos/{id}
  static Future<ApiResponse<Map<String, dynamic>>> getProductById(
    String productId,
  ) async {
    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/productos/$productId',
    );
  }

  /// Canjear un regalo/producto
  static Future<ApiResponse<Map<String, dynamic>>> redeemGift({
    required String giftId,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = {
      'giftId': giftId,
      if (additionalData != null) ...additionalData,
    };

    return await ApiConfig.postResponse<Map<String, dynamic>>(
      '/gifts/redeem',
      body: body,
    );
  }

  /// Obtener historial de canjes
  static Future<ApiResponse<Map<String, dynamic>>> getRedeemHistory({
    int? page,
    int? limit,
    String? status,
  }) async {
    final queryParams = <String, String>{};

    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/gifts/redeem-history',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Obtener categorías de regalos
  static Future<ApiResponse<Map<String, dynamic>>> getCategories() async {
    return await ApiConfig.getResponse<Map<String, dynamic>>(
      '/gifts/categories',
    );
  }
}
