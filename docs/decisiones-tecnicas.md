# Decisiones técnicas

Justificación de tecnologías elegidas, alternativas que se pueden inferir del código y trade-offs importantes. Basado en el estado actual del repositorio; donde no haya evidencia explícita se indica como suposición.

---

## Flutter y Dart

- **Decisión**: aplicación móvil con Flutter (Dart ^3.9.2).
- **Ventajas**: una sola base de código para Android e iOS, UI declarativa, buen rendimiento y ecosistema de paquetes.
- **Alternativas típicas**: React Native, Kotlin/Swift nativos. No hay documentación en el repo que explique por qué se eligió Flutter; se asume alineación con estándares del equipo o requisito del proyecto.
- **Trade-off**: se prioriza Android e iOS; web y escritorio tienen estructura generada por Flutter pero no son el foco (no se documentan como objetivo).

---

## Estado global: Provider

- **Decisión**: uso de **Provider** (ChangeNotifier) para puntos y productos; estado local con `setState` en el resto de la UI.
- **Ventajas**: sencillo, bien integrado con Flutter, suficiente para el tamaño actual de la app (puntos y catálogo compartidos entre varias pantallas).
- **Alternativas**: Riverpod, Bloc, GetX, Redux. No hay evidencia de que se hayan evaluado; el proyecto usa Provider desde el inicio.
- **Trade-off**: no hay inyección de dependencias ni capa de repositorios; los widgets y servicios llaman directamente a `ApiConfig` y a los providers, lo que simplifica el código pero acopla más la UI a la API.

---

## HTTP y capa API

- **Decisión**: paquete `http` con un cliente centralizado en `ApiConfig` (en móvil, `IOClient` con timeouts); métodos estáticos por dominio en `auth_api`, `user_api`, `points_api`, `gifts_api`.
- **Ventajas**: un solo punto para baseUrl, headers, idSession, timeouts y parseo de errores; reutilización de `ApiResponse<T>` y `parseResponse`.
- **Alternativas**: Dio (interceptors, cancelación), retrofit-style. No se usan en el proyecto.
- **Trade-off**: no hay interceptors formales (p. ej. refresh token o retry); la lógica de “reintentar” o “desloguear en 401” no está centralizada en el cliente.

---

## Autenticación: sesión por header

- **Decisión**: el backend devuelve `idSession` en el login; la app lo guarda y lo envía en el header `id-session`. No se usa JWT en headers ni refresh token en el código revisado.
- **Ventajas**: implementación simple; el backend controla la validez de la sesión.
- **Alternativas**: Bearer token, OAuth2, refresh token. No implementadas.
- **Trade-off**: si la sesión expira, el usuario verá errores 401 hasta que vuelva a hacer login; no hay flujo automático de renovación. La persistencia es en SharedPreferences (no cifrado); ver [pendientes.md](pendientes.md) sobre flutter_secure_storage.

---

## Persistencia local

- **Decisión**: **SharedPreferences** para sesión (user_session, is_logged_in, api_id_session), caché de puntos y caché de productos (con timestamp y TTL 1 h).
- **Ventajas**: API simple, suficiente para preferencias y caché pequeño; no requiere esquema ni migraciones.
- **Alternativas**: Hive, SQLite, flutter_secure_storage para datos sensibles. No se usan en el proyecto.
- **Trade-off**: SharedPreferences no está cifrado; los datos de sesión son sensibles. Para caché de listas grandes, no hay persistencia estructurada (solo JSON de productos/puntos); si el catálogo creciera mucho, podría valorarse otra estrategia.

---

## Navegación imperativa

- **Decisión**: **Navigator.push**, **pushReplacement**, **pushAndRemoveUntil** con **MaterialPageRoute**; no hay rutas nombradas ni GoRouter.
- **Ventajas**: fácil de seguir en código pequeño; no hay configuración de rutas.
- **Alternativas**: GoRouter, AutoRoute, rutas nombradas con `MaterialApp(routes: ...)`. No adoptadas.
- **Trade-off**: deep links y pruebas de navegación son más manuales; `pushNamedAndRemoveUntil('/', ...)` depende de que `'/'` sea el home por defecto (no hay mapa de rutas explícito). Ver [pendientes.md](pendientes.md).

---

## Modelos y parsing de API

- **Decisión**: modelos con **fromJson**/toJson manuales; **ApiResponse&lt;T&gt;** con soporte para formato `success`/`message`/`data` y legacy `status`/`message`/`data`; en muchos sitios se comprueba también `rawData`, `usuarioData`, y variantes en MAYÚSCULAS.
- **Ventajas**: flexibilidad ante respuestas heterogéneas del backend; no hay dependencia de code generation.
- **Alternativas**: json_serializable, freezed. No se usan.
- **Trade-off**: hay duplicación de lógica “extraer userData de apiResponse” en AuthService, ProfilePage, etc.; un cambio de contrato del backend puede obligar a tocar varios archivos.

---

## UI y tema

- **Decisión**: **Material 3** (ThemeData con useMaterial3), familia de fuentes **Shell** (varias variantes en `fonts/`), colores en **AppColors**, tema claro por defecto (ThemeMode.light).
- **Ventajas**: identidad visual Shell; tema centralizado.
- **Trade-off**: no hay modo oscuro como predeterminado; si se quisiera forzar oscuro o por sistema, bastaría con cambiar themeMode o leer preferencia del sistema.

---

## Plataformas y orientación

- **Decisión**: en `main.dart` se fija `DeviceOrientation.portraitUp` y `portraitDown`; la app está pensada para **portrait** en móvil.
- **Trade-off**: en tablets o landscape la experiencia no está optimizada; es una decisión consciente de enfoque móvil portrait.

---

## Testing

- **Decisión**: solo el **widget_test.dart** por defecto (counter); no hay tests unitarios de providers, AuthService ni tests de integración de flujos.
- **Trade-off**: bajo coste inicial, pero mayor riesgo al refactorizar o cambiar APIs; se recomienda añadir tests para login, canje y providers (ver [pendientes.md](pendientes.md)).

---

## Resumen de trade-offs importantes

| Área | Decisión actual | Coste / riesgo |
|------|------------------|----------------|
| Estado | Provider + setState | Escalable hasta cierto tamaño; sin DI formal. |
| API | Un cliente, métodos estáticos | Acoplamiento UI–API; sin interceptors (refresh, 401). |
| Auth | id-session en SharedPreferences | Sesión en claro; sin refresh token. |
| Navegación | Solo Navigator imperativo | Sin deep links ni rutas nombradas explícitas. |
| Parsing | Manual + rawData | Duplicación y fragilidad ante cambios del backend. |
| Tests | Mínimos | Refactors y cambios de API más arriesgados. |

Estas decisiones son coherentes con una app móvil de tamaño medio y un equipo que prioriza entrega; la documentación en [pendientes.md](pendientes.md) sugiere mejoras incrementales (arquitectura, rutas, seguridad, tests) para cuando el proyecto crezca o se requiera mayor mantenibilidad.
