# API - Estructura de Endpoints

Esta carpeta contiene todos los endpoints de la API organizados por funcionalidad.

## Estructura

- `auth_api.dart` - Endpoints de autenticación (login, registro, recuperación de contraseña, etc.)
- `user_api.dart` - Endpoints de usuarios (CRUD, perfil, etc.)
- `gifts_api.dart` - Endpoints de regalos/productos (listado, canje, categorías, etc.)
- `points_api.dart` - Endpoints de puntos (historial, estadísticas, canje, etc.)

## Configuración

La configuración general de la API se encuentra en `lib/api.dart`. Allí puedes configurar:

- URL base de la API (`baseUrl`)
- Timeout de las peticiones
- Manejo de tokens de autenticación
- Headers por defecto

## Uso

### Ejemplo básico

```dart
import 'package:app_shell/api/auth_api.dart';
import 'package:app_shell/api.dart';

// Login
final response = await AuthApi.login(
  email: 'usuario@ejemplo.com',
  password: 'contraseña123',
);

if (ApiConfig.isSuccess(response)) {
  final data = jsonDecode(response.body);
  // Guardar token
  await ApiConfig.setToken(data['token']);
} else {
  final error = ApiConfig.handleError(response);
  print('Error: ${error['message']}');
}
```

### Ejemplo con manejo de errores

```dart
import 'package:app_shell/api/user_api.dart';
import 'package:app_shell/api.dart';

try {
  final response = await UserApi.getCurrentUser();
  
  if (ApiConfig.isSuccess(response)) {
    final userData = jsonDecode(response.body);
    // Procesar datos del usuario
  } else {
    final error = ApiConfig.handleError(response);
    // Manejar error
  }
} catch (e) {
  // Manejar excepciones de red
  print('Error de conexión: $e');
}
```

## Agregar nuevos endpoints

Para agregar nuevos grupos de endpoints:

1. Crea un nuevo archivo en esta carpeta (ej: `products_api.dart`)
2. Sigue el patrón de los archivos existentes
3. Usa `ApiConfig` para realizar las peticiones HTTP
4. Documenta los endpoints en este README

## Notas

- Todos los endpoints usan el prefijo `/api` automáticamente
- Los tokens de autenticación se manejan automáticamente si están configurados
- El timeout por defecto es de 30 segundos
- Todas las peticiones incluyen los headers `Content-Type` y `Accept` por defecto

