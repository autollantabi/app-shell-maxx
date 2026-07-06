import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../api/gifts_api.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  Map<String, List<ProductModel>> _productsByCategory = {};
  bool _isLoading = false;
  String? _error;

  static const String _cacheKey = 'cached_products';
  static const String _cacheTimestampKey = 'cached_products_timestamp';
  static const Duration _cacheValidDuration = Duration(
    hours: 1,
  ); // Caché válido por 1 hora

  List<ProductModel> get products => _products;
  Map<String, List<ProductModel>> get productsByCategory => _productsByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get categories => _productsByCategory.keys
      .where((cat) => cat.toUpperCase() != 'CARRUSEL')
      .toList();

  /// Cargar productos desde caché
  Future<bool> _loadProductsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (cachedData != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();

        // Verificar si el caché aún es válido
        if (now.difference(timestamp) < _cacheValidDuration) {
          final List<dynamic> cachedProducts = jsonDecode(cachedData);
          final products = cachedProducts
              .map(
                (item) => ProductModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

          _products = products;
          _groupProductsByCategory();

          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // Error al cargar desde caché
    }
    return false;
  }

  /// Guardar productos en caché
  Future<void> _saveProductsToCache(List<ProductModel> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = products.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(productsJson));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Error al guardar en caché
    }
  }

  /// Cargar productos desde la API
  Future<void> loadProducts({bool forceRefresh = false}) async {
    // Si no es un refresh forzado, intentar cargar desde caché primero
    if (!forceRefresh) {
      final loadedFromCache = await _loadProductsFromCache();
      if (loadedFromCache) {
        // Cargar desde caché exitoso, NO actualizar en segundo plano
        // Solo usar el caché hasta que el usuario haga pull-to-refresh
        return;
      }
    }

    // Si no hay caché o es un refresh forzado, cargar desde API
    await _loadProductsFromApi(updateCache: true, showLoading: true);
  }

  /// Cargar productos desde la API
  Future<void> _loadProductsFromApi({
    bool updateCache = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final apiResponse = await GiftsApi.getGifts();

      if (apiResponse.success) {
        List<ProductModel> products = [];

        // Intentar obtener desde apiResponse.data (puede ser array o objeto)
        if (apiResponse.data != null) {
          if (apiResponse.data is List) {
            // Si es un array
            final dataList = apiResponse.data as List;
            for (var i = 0; i < dataList.length; i++) {
              final item = dataList[i];
              if (item is Map<String, dynamic>) {
                products.add(ProductModel.fromJson(item));
              }
            }
          } else if (apiResponse.data is Map<String, dynamic>) {
            // Si es un objeto único
            final data = apiResponse.data as Map<String, dynamic>;
            if (data.containsKey('ID') || data.containsKey('id')) {
              products.add(ProductModel.fromJson(data));
            }
          }
        }

        // Si no está en data, intentar desde rawData
        if (products.isEmpty && apiResponse.rawData != null) {
          // Primero verificar si rawData tiene 'body' (respuesta envuelta)
          Map<String, dynamic>? actualData = apiResponse.rawData;
          if (apiResponse.rawData!.containsKey('body')) {
            final body = apiResponse.rawData!['body'];
            if (body is Map<String, dynamic>) {
              actualData = body;
            } else if (body is String) {
              try {
                actualData = jsonDecode(body) as Map<String, dynamic>?;
              } catch (e) {
                // Error al parsear body
              }
            }
          }

          // Buscar 'data' en el JSON real
          if (actualData != null && actualData.containsKey('data')) {
            final data = actualData['data'];
            if (data is List) {
              // Si es un array
              for (var i = 0; i < data.length; i++) {
                final item = data[i];
                if (item is Map<String, dynamic>) {
                  products.add(ProductModel.fromJson(item));
                }
              }
            } else if (data is Map<String, dynamic>) {
              // Si es un objeto único
              if (data.containsKey('ID') || data.containsKey('id')) {
                products.add(ProductModel.fromJson(data));
              }
            }
          } else if (actualData != null && actualData.containsKey('data')) {
            final data = actualData['data'];
            if (data is List) {
              for (var i = 0; i < data.length; i++) {
                final item = data[i];
                if (item is Map<String, dynamic>) {
                  products.add(ProductModel.fromJson(item));
                }
              }
            }
          }
        }

        _products = products;
        _groupProductsByCategory();

        // Guardar en caché si se solicitó
        if (updateCache) {
          await _saveProductsToCache(products);
        }
      } else {
        // Solo mostrar error si no hay productos en caché
        if (_products.isEmpty) {
          _error = apiResponse.message;
        }
      }
    } catch (e) {
      // Solo mostrar error si no hay productos en caché
      if (_products.isEmpty) {
        _error = 'Error al cargar productos: $e';
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Agrupar productos por categoría
  void _groupProductsByCategory() {
    _productsByCategory.clear();
    for (var product in _products) {
      if (product.category.toUpperCase() == 'CARRUSEL') continue;
      if (!_productsByCategory.containsKey(product.category)) {
        _productsByCategory[product.category] = [];
      }
      _productsByCategory[product.category]!.add(product);
    }
  }

  /// Obtener productos de una categoría específica
  List<ProductModel> getProductsByCategory(String category) {
    return _productsByCategory[category] ?? [];
  }

  /// Refrescar productos (fuerza actualización desde API)
  Future<void> refresh() async {
    await loadProducts(forceRefresh: true);
  }

  /// Limpiar caché de productos
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      // Error al limpiar caché
    }
  }

  /// Resetear estado del provider (útil al hacer logout)
  void reset() {
    _products = [];
    _productsByCategory = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
