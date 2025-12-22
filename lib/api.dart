import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/api_response.dart';

/// Configuración centralizada de la API
class ApiConfig {
  // URL base de la API - Cambiar según tu entorno
  // static const String baseUrl = 'http://192.168.0.68:3202/api';
  static const String baseUrl = 'https://api.maxximundo.com/api/app-shell';

  // Timeout para las peticiones (en segundos)
  static const int timeoutSeconds = 30;

  // Clave para almacenar el idSession
  static const String _idSessionKey = 'api_id_session';

  /// Obtiene el idSession almacenado
  static Future<String?> getIdSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idSessionKey);
  }

  /// Guarda el idSession
  static Future<void> setIdSession(String idSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idSessionKey, idSession);
  }

  /// Elimina el idSession
  static Future<void> clearIdSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idSessionKey);
  }

  // Métodos legacy para compatibilidad (ahora usan idSession)
  static Future<String?> getToken() async => getIdSession();
  static Future<void> setToken(String token) async => setIdSession(token);
  static Future<void> clearTokens() async => clearIdSession();

  /// Construye la URL completa del endpoint
  static String buildUrl(String endpoint) {
    // Asegurar que el endpoint comience con /
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$cleanEndpoint';
  }

  /// Obtiene los headers por defecto para las peticiones
  static Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Agregar idSession de autenticación si es necesario
    if (includeAuth) {
      final idSession = await getIdSession();
      if (idSession != null) {
        headers['id-session'] = idSession;
      }
    }

    // Agregar headers adicionales si se proporcionan
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Realiza una petición HTTP GET
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    var url = buildUrl(endpoint);

    // Agregar query parameters si existen
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: queryParams).toString();
    }

    final headers = await getHeaders(
      includeAuth: includeAuth,
      additionalHeaders: additionalHeaders,
    );

    return await http
        .get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Realiza una petición HTTP POST
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final url = buildUrl(endpoint);
    final headers = await getHeaders(
      includeAuth: includeAuth,
      additionalHeaders: additionalHeaders,
    );

    return await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Realiza una petición HTTP PUT
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final url = buildUrl(endpoint);
    final headers = await getHeaders(
      includeAuth: includeAuth,
      additionalHeaders: additionalHeaders,
    );

    return await http
        .put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Realiza una petición HTTP PATCH
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final url = buildUrl(endpoint);
    final headers = await getHeaders(
      includeAuth: includeAuth,
      additionalHeaders: additionalHeaders,
    );

    return await http
        .patch(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Realiza una petición HTTP DELETE
  static Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final url = buildUrl(endpoint);
    final headers = await getHeaders(
      includeAuth: includeAuth,
      additionalHeaders: additionalHeaders,
    );

    return await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Maneja errores comunes de la API
  static Map<String, dynamic> handleError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      return errorData;
    } catch (e) {
      return {
        'error': 'Error desconocido',
        'message': response.body.isNotEmpty
            ? response.body
            : 'Error al procesar la respuesta',
        'statusCode': response.statusCode,
      };
    }
  }

  /// Verifica si la respuesta fue exitosa
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Parsea una respuesta HTTP a ApiResponse estándar
  static ApiResponse<T> parseResponse<T>(
    http.Response response, {
    T Function(Map<String, dynamic>)? dataParser,
  }) {
    try {
      if (response.body.isEmpty) {
        return ApiResponse<T>.error(message: 'Respuesta vacía del servidor');
      }

      final decodedBody = jsonDecode(response.body);
      Map<String, dynamic> jsonData;

      // Si el body decodificado es un Map, usarlo directamente
      if (decodedBody is Map<String, dynamic>) {
        jsonData = decodedBody;
      } else if (decodedBody is Map) {
        // Si es un Map genérico, convertirlo
        jsonData = Map<String, dynamic>.from(decodedBody);
      } else {
        // Si no es un Map, crear un error
        return ApiResponse<T>.error(
          message: 'Formato de respuesta inválido',
          rawData: {'statusCode': response.statusCode, 'body': response.body},
        );
      }

      // Si el status code no es exitoso, crear respuesta de error
      if (!isSuccess(response)) {
        // Si hay un mensaje de error, usarlo
        final errorMessage =
            jsonData['message'] as String? ??
            jsonData['error'] as String? ??
            'Error en la petición';
        return ApiResponse<T>.error(message: errorMessage, rawData: jsonData);
      }

      // Parsear como respuesta estándar
      return ApiResponse<T>.fromJson(jsonData, dataParser: dataParser);
    } catch (e) {
      // Si hay error al parsear, intentar parsear el body como string JSON
      try {
        final bodyStr = response.body.toString();
        if (bodyStr.startsWith('{') || bodyStr.startsWith('[')) {
          final decodedBody = jsonDecode(bodyStr);
          if (decodedBody is Map<String, dynamic>) {
            return ApiResponse<T>.fromJson(decodedBody, dataParser: dataParser);
          }
        }
      } catch (_) {
        // Si falla, continuar con el error original
      }

      // Si hay error al parsear, crear respuesta de error
      return ApiResponse<T>.error(
        message: 'Error al procesar la respuesta: ${e.toString()}',
        rawData: {'statusCode': response.statusCode, 'body': response.body},
      );
    }
  }

  /// Realiza una petición GET y retorna ApiResponse
  static Future<ApiResponse<T>> getResponse<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final response = await get(
        endpoint,
        queryParams: queryParams,
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );
      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición POST y retorna ApiResponse
  static Future<ApiResponse<T>> postResponse<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final response = await post(
        endpoint,
        body: body,
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );
      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición PUT y retorna ApiResponse
  static Future<ApiResponse<T>> putResponse<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final response = await put(
        endpoint,
        body: body,
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );
      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición PATCH y retorna ApiResponse
  static Future<ApiResponse<T>> patchResponse<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final response = await patch(
        endpoint,
        body: body,
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );
      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición PATCH con multipart form data (para archivos)
  static Future<ApiResponse<T>> patchMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, Uint8List>? files,
    Map<String, String>? fileNames,
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final url = buildUrl(endpoint);

      // Crear request multipart
      final request = http.MultipartRequest('PATCH', Uri.parse(url));

      // Agregar campos de texto
      request.fields.addAll(fields);

      // Agregar archivos si existen
      if (files != null) {
        files.forEach((key, bytes) {
          final fileName = fileNames?[key] ?? 'file.jpg';
          // Determinar el Content-Type basado en la extensión del archivo
          String contentType = 'image/jpeg';
          if (fileName.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else if (fileName.toLowerCase().endsWith('.gif')) {
            contentType = 'image/gif';
          }

          final file = http.MultipartFile.fromBytes(
            key,
            bytes,
            filename: fileName,
            contentType: http.MediaType.parse(contentType),
          );
          request.files.add(file);
        });
      }

      // Agregar headers (sin Content-Type, se establece automáticamente con el boundary)
      final headers = await getHeaders(
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );

      // Remover Content-Type del header porque multipart lo establece automáticamente
      // con el boundary correcto
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Enviar request
      final streamedResponse = await request.send().timeout(
        Duration(seconds: timeoutSeconds),
      );

      // Convertir streamed response a response normal
      final response = await http.Response.fromStream(streamedResponse);

      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e, stackTrace) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición DELETE y retorna ApiResponse
  static Future<ApiResponse<T>> deleteResponse<T>(
    String endpoint, {
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    try {
      final response = await delete(
        endpoint,
        includeAuth: includeAuth,
        additionalHeaders: additionalHeaders,
      );
      return parseResponse<T>(response, dataParser: dataParser);
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }
}
