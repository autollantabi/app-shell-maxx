import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/points_api.dart';

class PointsProvider with ChangeNotifier {
  int _availablePoints = 0;
  int _currentMonthPoints = 0;
  int _accumulatedPoints = 0;
  int _totalPoints = 0;
  int _extraPoints = 0;
  int _availableWithoutExtras = 0;
  bool _isLoading = false;
  String? _error;

  // Claves para el caché
  static const String _cacheKey = 'cached_points';
  static const String _cacheCurrentMonthKey = 'cached_current_month_points';
  static const String _cacheAccumulatedKey = 'cached_accumulated_points';
  static const String _cacheTotalPointsKey = 'cached_total_points';
  static const String _cacheExtraPointsKey = 'cached_extra_points';
  static const String _cacheAvailableWithoutExtrasKey =
      'cached_available_without_extras';
  static const String _cacheTimestampKey = 'cached_points_timestamp';
  static const Duration _cacheValidDuration = Duration(
    hours: 1,
  ); // Caché válido por 1 hora

  int get availablePoints => _availablePoints;
  int get currentMonthPoints => _currentMonthPoints;
  int get accumulatedPoints => _accumulatedPoints;
  int get totalPoints => _totalPoints;
  int get extraPoints => _extraPoints;
  int get availableWithoutExtras => _availableWithoutExtras;
  int get pendingPoints => _totalPoints - _availablePoints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar puntos desde caché
  Future<bool> _loadPointsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPoints = prefs.getInt(_cacheKey);
      final cachedCurrentMonthPoints = prefs.getInt(_cacheCurrentMonthKey);
      final cachedAccumulatedPoints = prefs.getInt(_cacheAccumulatedKey);
      final cachedTotalPoints = prefs.getInt(_cacheTotalPointsKey);
      final cachedExtraPoints = prefs.getInt(_cacheExtraPointsKey);
      final cachedAvailableWithoutExtras = prefs.getInt(
        _cacheAvailableWithoutExtrasKey,
      );
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (cachedPoints != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();

        if (now.difference(timestamp) < _cacheValidDuration) {
          _availablePoints = cachedPoints;
          _currentMonthPoints = cachedCurrentMonthPoints ?? 0;
          _accumulatedPoints = cachedAccumulatedPoints ?? 0;
          _totalPoints = cachedTotalPoints ?? 0;
          _extraPoints = cachedExtraPoints ?? 0;
          _availableWithoutExtras = cachedAvailableWithoutExtras ?? 0;
          _error = null;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // ignore: avoid_print
    }
    return false;
  }

  /// Guardar puntos en caché
  Future<void> _savePointsToCache(
    int points,
    int currentMonthPoints,
    int accumulatedPoints,
    int totalPoints, {
    int extraPoints = 0,
    int availableWithoutExtras = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheKey, points);
      await prefs.setInt(_cacheCurrentMonthKey, currentMonthPoints);
      await prefs.setInt(_cacheAccumulatedKey, accumulatedPoints);
      await prefs.setInt(_cacheTotalPointsKey, totalPoints);
      await prefs.setInt(_cacheExtraPointsKey, extraPoints);
      await prefs.setInt(
        _cacheAvailableWithoutExtrasKey,
        availableWithoutExtras,
      );
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {}
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

      Map<String, dynamic>? data = apiResponse.data;
      if (data == null && apiResponse.rawData != null) {
        final raw = apiResponse.rawData as Map<String, dynamic>;
        if (raw.containsKey('data') && raw['data'] is Map) {
          data = raw['data'] as Map<String, dynamic>;
        }
      }

      if (apiResponse.success && data != null) {
        final availablePoints = data['availablePoints'] as int? ?? 0;
        final currentMonthPoints = data['currentMonthPoints'] as int? ?? 0;
        final accumulatedPoints =
            data['accumulatedPoints'] as int? ??
            data['puntosAcumulados'] as int? ??
            0;
        final totalPoints = data['totalPoints'] as int? ?? 0;
        final extraPoints = data['extraPoints'] as int? ?? 0;
        final availableWithoutExtras =
            data['availableWithoutExtras'] as int? ?? 0;

        _availablePoints = availablePoints;
        _currentMonthPoints = currentMonthPoints;
        _accumulatedPoints = accumulatedPoints;
        _totalPoints = totalPoints;
        _extraPoints = extraPoints;
        _availableWithoutExtras = availableWithoutExtras;
        _error = null;

        if (updateCache) {
          await _savePointsToCache(
            availablePoints,
            currentMonthPoints,
            accumulatedPoints,
            totalPoints,
            extraPoints: extraPoints,
            availableWithoutExtras: availableWithoutExtras,
          );
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
  void updatePoints(
    int newPoints, {
    int? newCurrentMonthPoints,
    int? newAccumulatedPoints,
    int? newTotalPoints,
    int? newExtraPoints,
    int? newAvailableWithoutExtras,
  }) {
    _availablePoints = newPoints;
    if (newCurrentMonthPoints != null) {
      _currentMonthPoints = newCurrentMonthPoints;
    }
    if (newAccumulatedPoints != null) _accumulatedPoints = newAccumulatedPoints;
    if (newTotalPoints != null) _totalPoints = newTotalPoints;
    if (newExtraPoints != null) _extraPoints = newExtraPoints;
    if (newAvailableWithoutExtras != null) {
      _availableWithoutExtras = newAvailableWithoutExtras;
    }
    _savePointsToCache(
      newPoints,
      _currentMonthPoints,
      _accumulatedPoints,
      _totalPoints,
      extraPoints: _extraPoints,
      availableWithoutExtras: _availableWithoutExtras,
    );
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
      await prefs.remove(_cacheAccumulatedKey);
      await prefs.remove(_cacheTotalPointsKey);
      await prefs.remove(_cacheExtraPointsKey);
      await prefs.remove(_cacheAvailableWithoutExtrasKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {}
  }

  /// Resetear estado del provider (útil al hacer logout)
  void reset() {
    _availablePoints = 0;
    _currentMonthPoints = 0;
    _accumulatedPoints = 0;
    _totalPoints = 0;
    _extraPoints = 0;
    _availableWithoutExtras = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
