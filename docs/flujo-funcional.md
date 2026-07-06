# Flujos funcionales principales

Descripción paso a paso de los flujos principales del sistema: autenticación, onboarding, puntos, canje y perfil. Incluye auth, autorización y permisos según rol.

---

## 1. Arranque de la aplicación y auth inicial

1. **main.dart** arranca con `AuthWrapper` como `home` del `MaterialApp`.
2. **AuthWrapper** en `initState` llama a `_checkAuthStatus()`:
   - `AuthService.instance.isLoggedIn()` (lee SharedPreferences `is_logged_in`).
   - Si es true, `AuthService.getCurrentUser()` (lee `user_session`).
3. **Resultado**:
   - Si hay usuario válido → se muestra `MainLayout(user: _user)` (pantallas principales).
   - Si no hay sesión → se muestra `IntroPage` (splash con logo Shell).
4. Tras ~3 segundos, **IntroPage** hace `Navigator.pushReplacement(..., LoginPage())`.

**Autorización**: no hay comprobación de permisos en este paso; solo existencia de sesión guardada.

---

## 2. Flujo de login

1. **LoginPage** (paso email):
   - Usuario escribe email y pulsa continuar.
   - Se llama a `AuthApi.verifyPassword(email)` → POST `/auth/pre-login`.
   - Respuesta: `hasPassword` (bool), `id` (userId). Si no tiene contraseña se usa `id` para crearla.
2. **Segundo paso** según respuesta:
   - **Si tiene contraseña**: se muestra campo contraseña. Al enviar → `AuthApi.login(email, password)` → POST `/auth/login`. Respuesta: `idSession`, `usuarioData`.
   - **Si no tiene contraseña**: se muestran campos “nueva contraseña” y “confirmar”. Se llama a `UserApi.updatePassword(userId, password)` → PATCH `/usuarios/$userId/password`, y luego `AuthApi.login(email, password)`.
3. **AuthService.login**:
   - Si la API devuelve éxito, extrae `idSession` (de `data` o `rawData`) y llama a `ApiConfig.setIdSession(idSession)`.
   - Extrae `usuarioData` y construye `UserModel.fromJson(usuarioData)`.
   - Determina `hasCompletedOnboarding` según si `LAST_LOGIN` (o `lastLogin`) tiene valor.
   - Guarda en SharedPreferences: `user_session` (JSON del usuario), `is_logged_in = true`.
   - Retorna `LoginResult(user, hasCompletedOnboarding)`.
4. **Navegación tras login**:
   - `Navigator.pushReplacement(..., LoadingVideoPage(...))`.
5. **LoadingVideoPage** reproduce el video de bienvenida; al terminar:
   - Si `hasCompletedOnboarding == false` → `Navigator.pushReplacement(..., OnboardingPage(...))`.
   - Si `hasCompletedOnboarding == true` → `Navigator.pushReplacement(..., MainLayout(user: user))`.
6. **OnboardingPage**: PageView de slides; en el último, botón “Comenzar” → `Navigator.pushReplacement(..., MainLayout(user: user))`.

**Autorización**: el backend valida credenciales; la app solo guarda sesión y usuario. Los roles (`roleId`: 1=Manager, 2=Vendedor, 3=Influenciador) se usan después para mostrar/ocultar opciones (managers, influencers, dirección en canje).

---

## 3. Flujo “Olvidé mi contraseña”

1. Desde **LoginPage**, enlace “¿Olvidaste tu contraseña?” → `Navigator.push(..., ForgotPasswordPage())`.
2. **ForgotPasswordPage**: usuario ingresa email → `AuthApi.requestPasswordReset(email)` → POST `/password/request-reset`. Si éxito, navegación a **VerifyCodePage** con el email (y token si el backend lo devuelve).
3. **VerifyCodePage**: usuario ingresa OTP (6 dígitos). Se llama a `AuthApi.verifyOtp(token, otp)` → POST `/password/verify-otp`. Si es correcto, se navega a **ResetPasswordPage** pasando el `resetToken` (y datos necesarios).
4. **ResetPasswordPage**: usuario ingresa nueva contraseña y confirmación. Se llama a `AuthApi.resetPassword(resetToken, newPassword)` → POST `/password/reset`. Si éxito → `Navigator.pushAndRemoveUntil(..., LoginPage(), (_) => false)` para volver al login sin stack anterior.

**Autorización**: solo requiere conocer el email y el OTP correcto; no se usa sesión activa.

---

## 4. Flujo principal: Home, puntos y catálogo

1. **MainLayout** muestra un **PageView** con tres páginas: **GiftsPage** (índice 0), **ClubShellHome** (índice 1), **ProfilePage** (índice 2). La barra inferior **CustomBottomNav** cambia de pestaña con `PageController.animateToPage`, no con rutas del Navigator.
2. **Puntos**:
   - **PointsProvider** se usa en Home, Gifts y Perfil. En `loadPoints()` primero intenta caché (SharedPreferences, TTL 1 h); si no hay o está expirado, llama a `PointsApi.getMyPoints()` → GET `/puntos/me`, actualiza estado y guarda en caché.
   - Pull-to-refresh y tras un canje se llama `PointsProvider.refresh()` (fuerza API).
   - **Bono de Cumpleaños**: Se evalúa si es el cumpleaños del usuario y si no ha reclamado el bono en el año con `BirthdayService`. Si aplica, se muestra un `BirthdayPopup` y, al interactuar, llama a `PointsApi.claimBirthdayBonus(userId)`.
3. **Productos**:
   - **ProductsProvider** en `loadProducts()` usa caché (1 h) si existe; si no, `GiftsApi.getGifts()` → GET `/productos` (con query opcional category, etc.). Los productos se agrupan por categoría en memoria.
4. **ClubShellHome**: muestra saludo, tarjeta de puntos (disponibles, generados, extra), lista horizontal “Estos premios están listos para canjear” y carrusel de banners.
5. **GiftsPage**: tabs por categoría (desde `ProductsProvider.productsByCategory`), grid de **ProductCard**. Cada card puede navegar a **ProductDetailPage** con `user`, puntos y `productId`.

**Autorización**: todas las peticiones de puntos y productos llevan header `id-session`; el backend asocia la sesión al usuario. No hay comprobación de rol en la app para “ver” puntos o catálogo; la restricción es del backend.

---

## 5. Flujo de canje de producto

1. Usuario en **ProductDetailPage** (imagen, descripción, puntos, cantidad).
2. **Lógica de dirección** (según rol y categoría del producto):
   - **Vendedor (roleId == 2)**: no se requiere dirección de envío; se puede canjear sin `addressId`.
   - **Experiencias** (categoría): no se pide dirección.
   - **Modo relax** u otras: se usa la primera dirección o se muestra selector/diálogo de dirección.
3. Usuario confirma cantidad y, si aplica, dirección; pulsa “Canjear”.
4. Se llama a `PointsApi.redeemProduct(productId, addressId, comments, quantity)` → POST `/canjes` (body con `productId`, `addressId` opcional, `comments`, `quantity`).
5. Si la API responde éxito:
   - Se llama a `PointsProvider.refresh()` para actualizar puntos.
   - Se muestra pantalla de éxito (inline en ProductDetailPage con `_buildSuccessScreen` o similar). **RedeemSuccessPage** existe como pantalla independiente y en algún flujo usa `pushNamedAndRemoveUntil('/', ...)` (ruta '/' no definida en MaterialApp; ver [pendientes.md](pendientes.md)).
6. Usuario puede volver al listado o al home con `pop` o navegación equivalente.

**Autorización**: el backend valida que el usuario tenga puntos suficientes y, si aplica, que la dirección pertenezca al usuario. El rol solo afecta en la app a “pedir o no dirección”.

---

## 6. Flujo de perfil y cierre de sesión

1. **ProfilePage** recibe `user` y `onUserUpdated` desde MainLayout. Al cargar puede llamar a `AuthApi.getCurrentUser()` → GET `/auth/me` para refrescar datos y actualizar `user_session` y estado local.
2. **Edición de avatar**: imagen desde galería/cámara con `image_picker`, recorte con `image_cropper`, envío con `UserApi.updateUserWithImage(...)` → PATCH multipart `/usuarios/$userId`. Tras éxito se actualiza el usuario local y `onUserUpdated(updatedUser)` para refrescar el layout.
3. **Menú de perfil** (según rol):
   - **Comunes**: Direcciones, Premios canjeados, Gana Puntos Extra (Trivia, Participaciones, Cómo Participar), Ayuda, Política de privacidad, Cambiar contraseña.
   - **Managers**: para vendedores (lista de managers del vendedor).
   - **Influencers**: para managers (lista de influencers del manager); opción de añadir influencer (búsqueda por email y asociación).
4. **Cambiar contraseña**: **ChangePasswordPage** → `UserApi.changePassword(userId, currentPassword, newPassword)` → POST `/usuarios/change-password`.
5. **Cerrar sesión y sesión expirada**:
   - **Logout manual**: Se llama a `AuthService.logout()`: elimina `user_session`, `is_logged_in`, caché de productos y puntos, y `ApiConfig.clearIdSession()`. Se navega al login.
   - **Sesión expirada**: Si la API devuelve un status `401 Unauthorized`, `ApiConfig` notifica al `AuthService`, el cual levanta un `SessionExpiredPopup`. Cuando el usuario lo cierra, se le hace un logout automático y se le redirige al login.

**Autorización**: todas las acciones de perfil usan `id-session`; el backend restringe por usuario. Managers y vendedores ven opciones adicionales según `roleId` (1 o 2).

---

## 7. Flujo de Notificaciones

1. **Recepción**: Las notificaciones se obtienen a través de `NotificationsApi.getMyNotifications()`.
2. **Visualización**: Se muestran en una pantalla dedicada (`NotificationsPage`). Las notificaciones pueden filtrarse por leídas y no leídas (ej. `soloNoLeidas=true`).
3. **Interacción**: Al tocar una notificación, se invoca `NotificationsApi.markAsRead(id)` y se actualiza el estado local de la lista.

---

## Resumen de roles y permisos en la app

| Rol (roleId) | Nombre interno | Permisos visibles en la app |
|--------------|----------------|-----------------------------|
| 1 | Manager | Gestión de influencers asociados, direcciones, canjes con dirección según categoría. |
| 2 | Vendedor | Lista de managers, canje sin dirección de envío. |
| 3 | Influenciador | Catálogo, canjes con dirección, premios canjeados, direcciones, sin gestión de otros usuarios. |

La autorización real (qué puede hacer cada rol en el backend) la define la API; la app solo muestra u oculta pantallas y campos según `UserModel.roleId` / `type` (admin/manager/influencer).
