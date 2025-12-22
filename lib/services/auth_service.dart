import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../api/auth_api.dart';
import '../api.dart';

/// Resultado del login
class LoginResult {
  final UserModel user;
  final bool hasCompletedOnboarding;

  LoginResult({required this.user, required this.hasCompletedOnboarding});
}

class AuthService {
  static const String _userKey = 'user_session';
  static const String _isLoggedInKey = 'is_logged_in';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  // Verificar si el usuario está logueado
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Obtener usuario de la sesión
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        // Si hay error al parsear, limpiar la sesión
        await logout();
        return null;
      }
    }
    return null;
  }

  // Iniciar sesión y guardar usuario
  Future<LoginResult?> login(String email, String password) async {
    try {
      // Llamar a la API de autenticación
      final apiResponse = await AuthApi.login(email: email, password: password);

      if (apiResponse.success) {
        // Obtener idSession de la respuesta
        String? idSession = apiResponse.getValue<String>('idSession');

        // Si no está en data, buscar en rawData
        if (idSession == null && apiResponse.rawData != null) {
          idSession = apiResponse.rawData!['idSession']?.toString();
        }

        // Si no está en rawData directamente, buscar en rawData['data']
        if (idSession == null && apiResponse.rawData != null) {
          final data = apiResponse.rawData!['data'];
          if (data is Map<String, dynamic>) {
            idSession = data['idSession']?.toString();
          }
        }

        if (idSession != null && idSession.isNotEmpty) {
          await ApiConfig.setIdSession(idSession);
        }

        // Obtener datos del usuario desde usuarioData
        Map<String, dynamic>? userData;

        // Intentar obtener desde data primero
        if (apiResponse.data != null &&
            apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;
          if (data.containsKey('usuarioData')) {
            userData = data['usuarioData'] as Map<String, dynamic>?;
          }
        }

        // Si no está en data, intentar desde rawData
        if (userData == null && apiResponse.rawData != null) {
          if (apiResponse.rawData!.containsKey('usuarioData')) {
            userData =
                apiResponse.rawData!['usuarioData'] as Map<String, dynamic>?;
          } else if (apiResponse.rawData!.containsKey('data')) {
            final data = apiResponse.rawData!['data'];
            if (data is Map<String, dynamic> &&
                data.containsKey('usuarioData')) {
              userData = data['usuarioData'] as Map<String, dynamic>?;
            }
          }
        }

        if (userData == null) {
          return null;
        }

        // Verificar LAST_LOGIN para decidir si mostrar onboarding
        // Si LAST_LOGIN tiene fecha, no mostrar onboarding; si es null, mostrar onboarding
        final lastLogin = userData['LAST_LOGIN'] ?? userData['lastLogin'];
        final hasCompletedOnboarding =
            lastLogin != null && lastLogin.toString().isNotEmpty;

        // Convertir a UserModel
        final user = UserModel.fromJson(userData);

        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        await prefs.setBool(_isLoggedInKey, true);

        return LoginResult(
          user: user,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Limpiar datos de sesión del usuario
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
    
    // Limpiar caché de productos
    await prefs.remove('cached_products');
    await prefs.remove('cached_products_timestamp');
    
    // Limpiar caché de puntos
    await prefs.remove('cached_points');
    await prefs.remove('cached_current_month_points');
    await prefs.remove('cached_points_timestamp');
    
    // Limpiar idSession de la API
    await ApiConfig.clearIdSession();
  }

  // Actualizar información del usuario
  Future<void> updateUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Verificar si la sesión es válida (opcional: agregar expiración)
  Future<bool> isSessionValid() async {
    if (!await isLoggedIn()) return false;

    // Aquí podrías agregar lógica para verificar si la sesión expiró
    // Por ejemplo, verificar timestamp de último login
    return true;
  }
}
