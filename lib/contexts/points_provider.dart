import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/points_api.dart';

class PointsProvider with ChangeNotifier {
  int _availablePoints = 0;
  int _currentMonthPoints = 0;
  bool _isLoading = false;
  String? _error;

  // Claves para el caché
  static const String _cacheKey = 'cached_points';
  static const String _cacheCurrentMonthKey = 'cached_current_month_points';
  static const String _cacheTimestampKey = 'cached_points_timestamp';
  static const Duration _cacheValidDuration = Duration(
    hours: 1,
  ); // Caché válido por 1 hora

  int get availablePoints => _availablePoints;
  int get currentMonthPoints => _currentMonthPoints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar puntos desde caché
  Future<bool> _loadPointsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPoints = prefs.getInt(_cacheKey);
      final cachedCurrentMonthPoints = prefs.getInt(_cacheCurrentMonthKey);
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (cachedPoints != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();

        if (now.difference(timestamp) < _cacheValidDuration) {
          _availablePoints = cachedPoints;
          _currentMonthPoints = cachedCurrentMonthPoints ?? 0;
          _error = null;


          notifyListeners();
          return true;
        } else {
        }
      }
    } catch (e) {
    }
    return false;
  }

  /// Guardar puntos en caché
  Future<void> _savePointsToCache(int points, int currentMonthPoints) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheKey, points);
      await prefs.setInt(_cacheCurrentMonthKey, currentMonthPoints);
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
    }
  }

  /// Cargar puntos desde la API
  Future<void> loadPoints({bool forceRefresh = false}) async {
    // Si no es un refresh forzado, intentar cargar desde caché primero
    if (!forceRefresh) {
      final loadedFromCache = await _loadPointsFromCache();
      if (loadedFromCache) {
        // Cargar desde caché exitoso, actualizar en segundo plano sin mostrar loading
        _loadPointsFromApi(updateCache: true, showLoading: false);
        return;
      }
    }

    // Si no hay caché o es un refresh forzado, cargar desde API
    await _loadPointsFromApi(updateCache: true, showLoading: true);
  }

  /// Cargar puntos desde la API
  Future<void> _loadPointsFromApi({
    bool updateCache = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final apiResponse = await PointsApi.getMyPoints();


      // Imprimir rawData si está disponible
      if (apiResponse.rawData != null) {
      }


      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data as Map<String, dynamic>;

        // Imprimir todas las claves del objeto data
        for (var key in data.keys) {
        }

        final availablePoints = data['availablePoints'] as int? ?? 0;
        final currentMonthPoints = data['currentMonthPoints'] as int? ?? 0;
        _availablePoints = availablePoints;
        _currentMonthPoints = currentMonthPoints;
        _error = null;


        // Guardar en caché si se solicitó
        if (updateCache) {
          await _savePointsToCache(availablePoints, currentMonthPoints);
        }
      } else {
        // Solo mostrar error si no hay puntos en caché
        if (_availablePoints == 0) {
          _error = apiResponse.message;
        }
      }
    } catch (e) {
      // Solo mostrar error si no hay puntos en caché
      if (_availablePoints == 0) {
        _error = 'Error al cargar puntos: $e';
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Actualizar puntos manualmente (útil después de un canje)
  void updatePoints(int newPoints, {int? newCurrentMonthPoints}) {
    _availablePoints = newPoints;
    if (newCurrentMonthPoints != null) {
      _currentMonthPoints = newCurrentMonthPoints;
    }
    // Actualizar caché cuando se actualiza manualmente
    _savePointsToCache(newPoints, _currentMonthPoints);
    notifyListeners();
  }

  /// Refrescar puntos desde la API (ignora caché)
  Future<void> refresh() async {
    await loadPoints(forceRefresh: true);
  }

  /// Limpiar caché de puntos
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheCurrentMonthKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
    }
  }

  /// Resetear estado del provider (útil al hacer logout)
  void reset() {
    _availablePoints = 0;
    _currentMonthPoints = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
