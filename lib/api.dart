import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/api_response.dart';
import 'services/auth_service.dart';

/// Configuración centralizada de la API
class ApiConfig {
  // Cliente HTTP personalizado para mejor manejo de DNS en iOS
  static http.Client? _httpClient;
  
  // URL base manual (si se establece, se usa en lugar de la detección automática)
  static String? _manualBaseUrl;
  
  /// Obtiene el cliente HTTP configurado
  static http.Client get httpClient {
    if (_httpClient == null) {
      if (Platform.isIOS || Platform.isAndroid) {
        final ioClient = HttpClient()
          ..autoUncompress = true
          ..connectionTimeout = Duration(seconds: 15)
          ..idleTimeout = Duration(seconds: 15);
        _httpClient = IOClient(ioClient);
      } else {
        _httpClient = http.Client();
      }
    }
    return _httpClient!;
  }
  
  
  // URL base de la API - Se configura automáticamente según el modo de ejecución
  // Prioridad:
  // 1. URL manual (setBaseUrl)
  // 2. Modo debug (debug -> /dev, release -> sin /dev)
  static String get baseUrl {
    if (_manualBaseUrl != null) {
      return _manualBaseUrl!;
    }
    
    return kDebugMode
        ? 'https://api.maxximundo.com/api/app-shell/dev'
        : 'https://api.maxximundo.com/api/app-shell';
  }
  
  /// Establece manualmente la URL base (útil para forzar el uso de la URL pública en debug)
  static void setBaseUrl(String url) {
    _manualBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  
  /// Restablece la URL base a la configuración automática
  static void resetBaseUrl() {
    _manualBaseUrl = null;
  }


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
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
      'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
      'Connection': 'keep-alive',
    };

    if (includeAuth) {
      final idSession = await getIdSession();
      if (idSession != null) {
        headers['id-session'] = idSession;
      }
    }

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

    try {
      final response = await httpClient
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
      
      return response;
    } catch (e) {
      rethrow;
    }
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
    
    final bodyJson = body != null ? jsonEncode(body) : null;

    try {
      final response = await httpClient
          .post(
            Uri.parse(url),
            headers: headers,
            body: bodyJson,
          )
          .timeout(Duration(seconds: timeoutSeconds));
      
      return response;
    } catch (e) {
      rethrow;
    }
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

    try {
      final response = await httpClient
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: timeoutSeconds));
      
      return response;
    } catch (e) {
      rethrow;
    }
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

    try {
      final response = await httpClient
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: timeoutSeconds));
      
      return response;
    } catch (e) {
      rethrow;
    }
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

    try {
      final response = await httpClient
          .delete(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
      
      return response;
    } catch (e) {
      rethrow;
    }
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

  /// Maneja errores de conexión y retorna un mensaje descriptivo
  static String handleConnectionError(dynamic error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('name or service not known')) {
        return 'No se puede conectar al servidor. Verifica tu conexión a internet.';
      } else if (message.contains('connection refused')) {
        return 'El servidor rechazó la conexión.';
      } else if (message.contains('connection timed out')) {
        return 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      } else if (message.contains('network is unreachable')) {
        return 'Red no disponible. Verifica tu conexión a internet.';
      }
      return 'Error de conexión: ${error.message}';
    }
    
    if (error is TimeoutException) {
      return 'Tiempo de espera agotado.';
    }
    
    return 'Error de conexión. Por favor, intenta nuevamente.';
  }

  /// Parsea una respuesta HTTP a ApiResponse estándar
  static ApiResponse<T> parseResponse<T>(
    http.Response response, {
    T Function(Map<String, dynamic>)? dataParser,
    bool check401 = true,
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
        // Si es 401 (Unauthorized) y check401 es verdadero, notificar expiración de sesión
        if (response.statusCode == 401 && check401) {
          AuthService.instance.notifySessionExpired();
        }

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

      // Si hay error al parsear, puede ser una respuesta HTML de error
      // Intentar extraer el mensaje de error del HTML
      String friendlyErrorMessage = 'Error al procesar la respuesta';
      
      if (response.body.contains('MulterError: File too large')) {
        friendlyErrorMessage = 'La imagen es demasiado grande. Por favor, selecciona una imagen más pequeña o recórtala.';
      } else if (response.body.contains('File too large')) {
        friendlyErrorMessage = 'La imagen es demasiado grande. Por favor, selecciona una imagen más pequeña o recórtala.';
      } else if (response.body.contains('<pre>')) {
        // Intentar extraer el mensaje del tag <pre>
        final preMatch = RegExp(r'<pre>(.*?)</pre>', dotAll: true).firstMatch(response.body);
        if (preMatch != null) {
          String errorText = preMatch.group(1) ?? '';
          // Limpiar tags HTML
          errorText = errorText.replaceAll(RegExp(r'<[^>]+>'), ' ');
          errorText = errorText.replaceAll('&nbsp;', ' ');
          errorText = errorText.trim();
          
          // Detectar errores comunes y dar mensajes amigables
          if (errorText.contains('File too large') || errorText.contains('MulterError')) {
            friendlyErrorMessage = 'La imagen es demasiado grande. Por favor, selecciona una imagen más pequeña o recórtala.';
          } else if (errorText.contains('Unauthorized') || errorText.contains('Forbidden')) {
            friendlyErrorMessage = 'No tienes permisos para realizar esta acción.';
          } else if (errorText.contains('Not Found')) {
            friendlyErrorMessage = 'El recurso solicitado no fue encontrado.';
          } else if (errorText.length < 200) {
            // Si el mensaje no es muy largo, usarlo directamente
            friendlyErrorMessage = errorText;
          } else {
            friendlyErrorMessage = 'Ha ocurrido un error. Por favor, intenta nuevamente.';
          }
        }
      }
      
      return ApiResponse<T>.error(
        message: friendlyErrorMessage,
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
      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
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
      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
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
      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
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
      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
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

      // Enviar request usando el cliente HTTP personalizado
      final streamedResponse = await httpClient.send(request).timeout(
        Duration(seconds: timeoutSeconds),
      );

      // Convertir streamed response a response normal
      final response = await http.Response.fromStream(streamedResponse);

      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
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
      return parseResponse<T>(response, dataParser: dataParser, check401: includeAuth);
    } catch (e) {
      return ApiResponse<T>.error(
        message: handleConnectionError(e),
      );
    }
  }
}
