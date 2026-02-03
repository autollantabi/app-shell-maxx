# APIs e integraciones externas

Documentación de los clientes HTTP y de las APIs consumidas por la aplicación Shell Maxx.

---

## Instancia HTTP y cliente utilizado

- **Paquete**: `http` (y `http/io_client.dart` para entornos con `dart:io`).
- **Configuración**: centralizada en `lib/api.dart` mediante la clase estática `ApiConfig`.
  - **Cliente**: en iOS/Android se usa `IOClient` con `HttpClient` configurado (`autoUncompress: true`, `connectionTimeout` e `idleTimeout` de 15 s). En otros entornos se usa `http.Client()` por defecto.
  - **Timeout**: 30 segundos para todas las peticiones.
  - **Headers por defecto**: `Content-Type: application/json`, `Accept: application/json`, `User-Agent` (simulado Safari móvil), `Accept-Language: es-ES,...`, `Connection: keep-alive`. Si `includeAuth: true`, se añade `id-session` con el valor almacenado en SharedPreferences.

Todas las llamadas pasan por `ApiConfig.get`, `post`, `put`, `patch`, `delete` o por los helpers `getResponse`, `postResponse`, etc., que devuelven `ApiResponse<T>` y aplican `parseResponse` y `handleConnectionError`.

---

## URL y entornos

| Entorno  | URL base |
|----------|----------|
| Debug    | `https://api.maxximundo.com/api/app-shell/dev` |
| Release  | `https://api.maxximundo.com/api/app-shell` |

- La URL se elige en tiempo de ejecución según `kDebugMode` (Flutter).
- Se puede sobrescribir con `ApiConfig.setBaseUrl(url)` y restablecer con `ApiConfig.resetBaseUrl()`.

---

## Autenticación

- **Mecanismo**: sesión por identificador. El backend devuelve `idSession` en la respuesta de login; la app lo guarda con `ApiConfig.setIdSession(idSession)` y lo envía en el header **`id-session`** en todas las peticiones autenticadas.
- No se usa Bearer JWT ni refresh token en el código actual; la persistencia de sesión es local (SharedPreferences) hasta que el usuario cierra sesión o se limpia la app.

---

## Resumen por API / dominio

Los “servicios” que consume la app se agrupan en módulos bajo `lib/api/`. A continuación se listan los archivos, los endpoints representativos y qué partes de la app los usan.

### 1. Auth (`lib/api/auth_api.dart`)

| Endpoint | Método | Uso en la app | Notas |
|----------|--------|----------------|-------|
| `/auth/pre-login` | POST | Login: verificar si el usuario tiene contraseña | Body: `{ "email": "..." }`. Respuesta: `hasPassword`, `id` (userId). |
| `/auth/login` | POST | Login con email y contraseña | Body: `email`, `password`. Respuesta: `idSession`, `usuarioData`. |
| `/auth/logout` | POST | Cerrar sesión | Con header `id-session`. |
| `/auth/me` | GET | Obtener usuario actual (refresco de perfil) | Con header `id-session`. |
| `/auth/update-last-login` | POST | Actualizar último login | Body: `userId`. |
| `/password/request-reset` | POST | Recuperar contraseña: solicitar reset | Body: `{ "email": "..." }`. |
| `/password/verify-otp` | POST | Verificar OTP de recuperación | Body: `token`, `otp`. |
| `/password/reset` | POST | Restablecer contraseña | Body: `resetToken`, `newPassword`. |
| `/auth/forgot-password` | POST | (Legacy) Solicitar recuperación | Mantenido por compatibilidad. |
| `/auth/verify-code` | POST | Verificar código (flujo alternativo) | Body: `email`, `code`. |
| `/auth/register` | POST | Registro (expuesto en API, uso en app no revisado en detalle) | Body: `name`, `email`, `password`, etc. |
| `/auth/refresh-token` | POST | Refresh token (expuesto, uso no verificado) | Body: `refreshToken`. |

**Servicios/pantallas que usan AuthApi**: `AuthService` (login, sesión), `LoginPage`, `LoadingVideoPage`, `ForgotPasswordPage`, `VerifyCodePage`, `ResetPasswordPage`, `ProfilePage` (getCurrentUser, logout).

---

### 2. Usuario y direcciones (`lib/api/user_api.dart`)

| Endpoint | Método | Uso en la app | Notas |
|----------|--------|----------------|-------|
| `/usuarios/change-password` | POST | Cambiar contraseña desde perfil | Body: `userId`, `currentPassword`, `newPassword`. |
| `/usuarios/$userId/password` | PATCH | Actualizar contraseña (crear contraseña en primer login) | Body: `password`. |
| `/direcciones/user/$userId` | GET | Obtener direcciones del usuario | Usado en direcciones y en flujo de canje. |
| `/usuarios/$userId` | PATCH (multipart) | Actualizar perfil y/o imagen | Campos: name, lastname, card_id, email, phone, roleId, birth_date, access; archivo: `perfilImage`. |
| `/manager-influencers/my-influencers` | GET | Listar influencers del manager | Perfil → Influencers. |
| `/manager-influencers` | POST | Asociar influencer a manager | Body: `influencerId`, `managerId`, `notes`. |
| `/manager-influencers/$associationId` | DELETE | Eliminar asociación manager–influencer | |
| `/manager-influencers/manager/$managerId/influencers` | GET | Influencers de un manager (vendedor) | Managers / detalle manager. |
| `/manager-vendedor/vendedor/$vendedorId/managers` | GET | Managers de un vendedor | Perfil → Managers (vendedor). |
| `/usuarios/search-influencer` | POST | Buscar influencer por email | Body: `email`. Add influencer. |
| `/usuarios/influencer` | POST | Agregar influencer | Body: influencerData. |
| `/usuarios/$userId` | PATCH | Actualizar influencer | Body: influencerData. |

**Servicios/pantallas**: `ProfilePage`, `AddressesPage`, `ChangePasswordPage`, `ManagersPage`, `ManagerInfluencersPage`, `AddInfluencerPage`, `AssociatedProfilesPage`, y flujo de login (crear contraseña vía `updatePassword`).

---

### 3. Puntos y canjes (`lib/api/points_api.dart`)

| Endpoint | Método | Uso en la app | Notas |
|----------|--------|----------------|-------|
| `/puntos/me` | GET | Puntos del usuario (disponibles, mes, acumulados, totales, extra) | Usado por `PointsProvider`. |
| `/points/current` | GET | Puntos actuales (alternativo) | Expuesto en API. |
| `/points/history` | GET | Historial de puntos | Query: page, limit, type, startDate, endDate. |
| `/points/add` | POST | (Admin) Agregar puntos | Body: points, reason, etc. |
| `/points/redeem` | POST | Canjear puntos genérico | Body: points, reason. |
| `/points/stats` | GET | Estadísticas de puntos | Query: startDate, endDate. |
| `/canjes/mis-canjes` | GET | Mis canjes (historial) | Redeemed prizes. |
| `/canjes` | POST | Canjear un producto | Body: `productId`, `addressId` (opcional), `comments`, `quantity`. Vendedor puede enviar sin `addressId`. |

**Servicios/pantallas**: `PointsProvider`, `ProductDetailPage` (canje), `RedeemedPrizesPage`, Home y Gifts (muestra de puntos).

---

### 4. Productos / regalos (`lib/api/gifts_api.dart`)

| Endpoint | Método | Uso en la app | Notas |
|----------|--------|----------------|-------|
| `/productos` | GET | Lista de productos (catálogo) | Query: page, limit, category, search, filters. Usado por `ProductsProvider`. |
| `/gifts/$giftId` | GET | Detalle de un regalo por ID | Alternativo a producto por ID (uso concreto no revisado en detalle). |
| `/gifts/redeem` | POST | Canje de regalo (alternativo) | Body: giftId, additionalData. En el flujo principal de canje se usa `PointsApi.redeemProduct` (`/canjes`). |
| `/gifts/redeem-history` | GET | Historial de canjes de regalos | Query: page, limit, status. |
| `/gifts/categories` | GET | Categorías de regalos | Expuesto; categorías de productos pueden venir también del listado. |

**Servicios/pantallas**: `ProductsProvider`, `GiftsPage`, `ProductDetailPage`.

---

## Riesgos y dependencias

- **Un solo backend**: toda la app depende de `api.maxximundo.com`. Caídas o cambios de contrato afectan login, puntos, productos y canjes.
- **Sesión en SharedPreferences**: el `id-session` se guarda en claro. No hay uso de `flutter_secure_storage` en el código revisado.
- **Formato de respuesta heterogéneo**: la API a veces devuelve `data`, `usuarioData`, o datos en `rawData`/`body`. Los modelos y `AuthService`/providers contemplan varias variantes (mayúsculas/minúsculas, distintos nombres de campo); cambios en el backend pueden requerir ajustes en el parsing.
- **Rutas de regalos vs productos**: existen tanto `/productos` como `/gifts/*`. El canje principal usa `/canjes` (PointsApi); conviene mantener consistencia con el backend al añadir nuevas pantallas o flujos.

Para detalles de implementación (headers, parseo, manejo de errores), ver `lib/api.dart` y los archivos `lib/api/*_api.dart`.
