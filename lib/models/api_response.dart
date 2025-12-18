/// Modelo estándar para las respuestas de la API
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? rawData;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.rawData,
  });

  /// Crea una respuesta exitosa
  factory ApiResponse.success({
    required String message,
    T? data,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      rawData: rawData,
    );
  }

  /// Crea una respuesta de error
  factory ApiResponse.error({
    required String message,
    T? data,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: data,
      rawData: rawData,
    );
  }

  /// Parsea una respuesta desde un Map
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? dataParser,
  }) {
    try {
      // Verificar si tiene el formato nuevo {success: true/false, message: "", data: {}}
      if (json.containsKey('success')) {
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';
      final dataJson = json['data'] as Map<String, dynamic>?;

      T? parsedData;
      if (dataParser != null && dataJson != null) {
        try {
          parsedData = dataParser(dataJson);
        } catch (e) {
          // Si falla el parseo, continuar sin data
        }
      }

      return ApiResponse<T>(
        success: success,
        message: message,
        data: parsedData,
        rawData: json,
      );
    }

    // Verificar si tiene el formato antiguo {status: "Ok!", message: "", data: {...}}
    if (json.containsKey('status')) {
      final status = json['status'] as String? ?? '';
      final success =
          status.toLowerCase().contains('ok') ||
          status.toLowerCase() == 'success';
      final message = json['message'] as String? ?? '';

      // Si tiene un campo 'data', puede ser un objeto, array, o cualquier tipo
      dynamic dataValue;
      Map<String, dynamic>? dataJson;

      if (json.containsKey('data')) {
        dataValue = json['data'];

        // Si data es un Map, usarlo como dataJson
        if (dataValue is Map<String, dynamic>) {
          dataJson = dataValue;
        } else if (dataValue is List) {
          // Si data es un array, guardarlo directamente en dataValue
          // No intentar convertirlo a Map
        }
      } else {
        // Si no tiene 'data', extraer todos los campos que no sean 'status' o 'message'
        dataJson = <String, dynamic>{};
        json.forEach((key, value) {
          if (key != 'status' && key != 'message') {
            dataJson![key] = value;
          }
        });
        if (dataJson.isEmpty) {
          dataJson = null;
        }
      }

      T? parsedData;
      if (dataParser != null && dataJson != null) {
        try {
          parsedData = dataParser(dataJson);
        } catch (e) {
          // Si falla el parseo, continuar sin data
        }
      }

      // Si dataValue es un array o cualquier otro tipo, usarlo directamente
      T? finalData;
      if (parsedData != null) {
        finalData = parsedData;
      } else if (dataValue != null) {
        // Si dataValue es un List o cualquier otro tipo, intentar usarlo directamente
        try {
          finalData = dataValue as T?;
        } catch (e) {
          // Si el cast falla, intentar con dataJson
          if (dataJson != null) {
            try {
              finalData = dataJson as T?;
            } catch (e2) {
              // Si ambos casts fallan, dejar finalData como null
            }
          }
        }
      } else if (dataJson != null) {
        try {
          finalData = dataJson as T?;
        } catch (e) {
          // Si el cast falla, dejar finalData como null
        }
      }

      return ApiResponse<T>(
        success: success,
        message: message,
        data: finalData,
        rawData: json,
      );
    }

      // Si no tiene ninguno de los formatos esperados, asumir éxito si el status code es 200-299
      // y parsear todo el JSON como data
      return ApiResponse<T>(
        success: true,
        message: json['message'] as String? ?? '',
        rawData: json,
      );
    } catch (e) {
      // Si hay un error al parsear, retornar una respuesta de error
      return ApiResponse<T>(
        success: false,
        message: 'Error al parsear la respuesta: ${e.toString()}',
        rawData: json,
      );
    }
  }

  /// Obtiene un valor del rawData por clave
  T? getValue<T>(String key) {
    return rawData?[key] as T?;
  }

  /// Verifica si la respuesta tiene un campo específico
  bool hasField(String key) {
    return rawData?.containsKey(key) ?? false;
  }
}
