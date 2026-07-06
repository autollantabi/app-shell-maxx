# Guía del proyecto (onboarding)

Resumen para que un desarrollador nuevo entienda qué es el proyecto, cómo empezar, dónde está cada cosa y cómo añadir funcionalidad.

---

## Qué es el proyecto

**Shell Maxx** (paquete `app_shell`) es la app móvil del programa de lealtad Club Shell Maxx. Los usuarios (influenciadores, managers, vendedores) pueden:

- Iniciar sesión con email y contraseña (o crear contraseña en el primer acceso).
- Ver sus puntos (disponibles, del mes, acumulados, extra) y ganar puntos extra mediante Trivia Futbolera o Participaciones.
- Ver un catálogo de productos por categoría y canjear puntos por productos.
- Gestionar perfil (avatar, direcciones, premios canjeados) y, según rol, managers e influencers.
- Recibir y leer notificaciones, y obtener un bono de puntos en su cumpleaños.
- Recuperar contraseña por email y OTP.

Está desarrollada en **Flutter**, orientada a **Android e iOS** en **portrait**. La lógica de negocio y datos dependen de un backend en `https://api.maxximundo.com` (API REST con sesión por header `id-session`).

---

## Cómo empezar

1. **Leer** [README.md](../README.md) y [docs/indice.md](indice.md) para tener la visión general y el orden de lectura recomendado.
2. **Configurar el entorno** siguiendo [docs/setup.md](setup.md): Flutter, dependencias, ejecución local.
3. **Revisar la arquitectura** en [docs/arquitectura.md](arquitectura.md): carpetas, responsabilidades, cómo se añaden pantallas y providers.
4. **Consultar APIs** en [docs/apis.md](apis.md) para saber qué endpoints se usan y desde dónde.
5. **Seguir los flujos** en [docs/flujo-funcional.md](flujo-funcional.md) para entender login, canje, perfil y roles.

---

## Dónde está cada cosa

| Necesito... | Dónde está |
|-------------|-------------|
| Punto de entrada, providers globales | `lib/main.dart` |
| Configuración HTTP, baseUrl, idSession | `lib/api.dart` |
| Endpoints por dominio | `lib/api/auth_api.dart`, `user_api.dart`, `points_api.dart`, `gifts_api.dart` |
| Estado global (puntos, productos) | `lib/contexts/points_provider.dart`, `products_provider.dart` |
| Sesión y usuario actual | `lib/services/auth_service.dart` |
| Layout principal (3 tabs) | `lib/layouts/main_layout.dart` |
| Pantallas de login, recuperar contraseña, video, onboarding | `lib/pages/auth/`, `lib/pages/onboarding/` |
| Home, regalos, detalle producto | `lib/pages/home/`, `lib/pages/gifts/` |
| Perfil, direcciones, managers, influencers, ayuda, etc. | `lib/pages/profile/` |
| Modelos de datos | `lib/models/` (api_response, user_model, product_model) |
| Tema y colores | `lib/theme/app_colors.dart`, `app_theme.dart` |
| Componentes reutilizables | `lib/widgets/` (custom_bottom_nav, product_card) |
| Assets (imágenes, video) | `assets/images/`, `assets/videos/` |
| Fuentes Shell | `fonts/`, declaradas en `pubspec.yaml` |
| Configuración Android (firma, namespace) | `android/app/build.gradle.kts`, `android/FIRMA_APP.md` |
| Configuración iOS | `ios/Runner/`, `ios/Runner/Info.plist` |

---

## APIs e integraciones (resumen)

- **Una sola API REST**: base `https://api.maxximundo.com/api/app-shell` (o `/api/app-shell/dev` en debug).
- **Autenticación**: header `id-session` con el valor devuelto en el login; no Bearer JWT. Si el token expira (401), se muestra un popup y se fuerza el logout.
- **Módulos**: Auth (login, logout, recuperar contraseña, me), User (perfil, direcciones, managers/influencers), Points (puntos, canjes), Gifts/Productos (catálogo) y Notificaciones.
- Detalle de endpoints, servicios que los usan y riesgos: [docs/apis.md](apis.md).

---

## Flujo típico para añadir una pantalla o funcionalidad

1. **Nueva pantalla**:
   - Crear `lib/pages/<flujo>/<nombre>_page.dart`.
   - Navegar con `Navigator.push(context, MaterialPageRoute(builder: (_) => MiPagina(...)))`.
   - Si debe salir en el menú de perfil, añadir un ítem en `profile_page.dart` que haga ese push.

2. **Nuevo endpoint**:
   - Añadir método estático en el `*_api.dart` correspondiente usando `ApiConfig.getResponse`/`postResponse`/etc.
   - Usar `ApiResponse<T>` y, si hace falta, un modelo en `lib/models/` con `fromJson`/`toJson`.

3. **Nuevo estado global**:
   - Crear un `ChangeNotifier` en `lib/contexts/`.
   - Registrarlo en `MultiProvider` en `main.dart`.
   - Consumir con `context.read<MiProvider>()` o `Consumer<MiProvider>`.

4. **Cambios en tema**: editar `lib/theme/app_colors.dart` y/o `app_theme.dart`.

---

## Notas recientes (comportamiento actual)

- **Catálogo de regalos**: Las cards de producto son compactas; la imagen se muestra completa (sin recortar) y el bloque de puntos y botón “Canjear” queda siempre alineado abajo. Si al usuario le faltan puntos, el texto “Te faltan X puntos” reserva su espacio para que todas las cards tengan la misma altura y el grid no se descuadre.
- **Cantidad en el canje**: Los productos pueden traer un campo `quantity` (cantidad de unidades que incluye ese canje). Cuando es mayor que 1, se muestra un chip en la esquina inferior derecha de la imagen con “x2”, “x3”, etc. Es solo informativo, no indica stock.
- **Manejo de Sesión Expirada**: Si cualquier endpoint devuelve un HTTP 401, el cliente (`ApiConfig`) notifica globalmente a la app y se despliega el `SessionExpiredPopup`. Tras aceptarlo, se limpia la sesión y el usuario vuelve al login.
- **Bono de Cumpleaños**: Se evalúa al iniciar. Si es el cumpleaños del usuario, se levanta el `BirthdayPopup` para otorgar un bono a través de la API, previniendo que se muestre más de una vez en el mismo año.
- **Influencers y manager**: Al agregar o actualizar un influencer, se envía el código SAP del manager (`manager_sap_code`), que se obtiene de los datos del manager en la lista de managers (vendedor → managers → al abrir un manager se pasa su `sapCode` hasta la pantalla de agregar influencer).
- **Depuración**: En el código no se usan `debugPrint` ni `print`; los errores de red o API no se imprimen en consola desde la app.

---

## Decisiones históricas y código legado relevante

- **Rutas**: no hay rutas nombradas ni GoRouter; toda la navegación es imperativa con `Navigator` y `MaterialPageRoute`. En `profile_page` y `redeem_success_page` se usa `pushNamedAndRemoveUntil('/', ...)`; la ruta `'/'` no está registrada, pero en Flutter el `home` suele actuar como ruta inicial, por lo que puede llevar a AuthWrapper. Ver [pendientes.md](pendientes.md).
- **Respuestas de API**: el backend a veces devuelve `data`, `usuarioData`, campos en MAYÚSCULAS o en `rawData`/`body`. Los modelos y AuthService/providers intentan varias variantes; es código “defensivo” ante cambios de formato.
- **Roles**: `UserType` (admin, manager, influencer) y `roleId` (1=Manager, 2=Vendedor, 3=Influenciador). En parte del código se usa `type`, en otra `roleId`/`isManagerByRole`; conviene ser consistente al tocar lógica de permisos.
- **Canje**: el flujo principal usa `PointsApi.redeemProduct` → POST `/canjes`. Existe también `GiftsApi.redeemGift` → `/gifts/redeem`; no es el flujo principal de canje en la app.
- **Caché**: puntos y productos se cachean en SharedPreferences con TTL de 1 hora; pull-to-refresh y tras canje fuerzan refresh. Al hacer logout se limpia caché de puntos y productos.

---

## Despliegue y builds

- **Android release**: requiere `android/key.properties` y keystore (no en repo). Ver [android/FIRMA_APP.md](../android/FIRMA_APP.md) y [docs/despliegue.md](despliegue.md).
- **iOS**: certificados y perfiles en Xcode; ver [docs/despliegue.md](despliegue.md).
- No hay flavors; solo diferencia debug/release para la URL base de la API.

---

## Contacto o autor

No está definido en el repositorio. Si tu equipo tiene un responsable técnico o mantenedor, conviene añadir esa información aquí o en el README.
