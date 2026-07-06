# Arquitectura del sistema

Descripción de la arquitectura general, estructura de carpetas, responsabilidades y patrones utilizados en el proyecto Shell Maxx.

---

## Arquitectura general

El proyecto no sigue una arquitectura formal (Clean Architecture, Hexagonal, etc.). Usa un enfoque **orientado a pantallas y servicios**:

- **Pantallas (pages/)**: UI y parte de la lógica de presentación (formularios, navegación, llamadas a API desde el widget).
- **Servicios (services/)**: lógica reutilizable (por ejemplo `AuthService` para login/logout y persistencia de sesión).
- **API (api.dart + api/)**: capa HTTP centralizada; los módulos `*_api.dart` exponen endpoints por dominio.
- **Modelos (models/)**: DTOs y representación de entidades (usuario, producto, respuesta API).
- **Contextos (contexts/)**: estado global con **Provider** (puntos, productos).

No existe capa explícita de “casos de uso” ni inyección de dependencias formal; las páginas y servicios usan directamente `ApiConfig`, `AuthService.instance` y `Provider`.

---

## Diagrama de flujo de datos

```
                    ┌─────────────────┐
                    │   API Backend   │
                    │ api.maxximundo  │
                    └────────┬────────┘
                             │ HTTPS (id-session en headers)
                             ▼
                    ┌─────────────────┐
                    │   api.dart      │
                    │  ApiConfig     │
                    │ (GET/POST/...)  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ auth_api      │   │ user_api      │   │ points_api    │
│ gifts_api     │   │               │   │               │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ AuthService   │   │ UserModel     │   │ PointsProvider│
│ (session)     │   │ (perfil)      │   │ ProductsProv. │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                    ┌─────────────────┐
                    │  Pages / UI     │
                    │  (Provider +    │
                    │   setState)     │
                    └─────────────────┘
```

- **Autenticación**: login → API devuelve `idSession` y datos de usuario → `ApiConfig.setIdSession` + `AuthService` guarda usuario y `is_logged_in` en SharedPreferences. Las peticiones posteriores envían el header `id-session`.
- **Puntos y productos**: los providers cargan primero desde caché (SharedPreferences) si existe y no está expirado; luego refrescan desde la API. Pull-to-refresh y tras canje llaman a `refresh()`.

---

## Árbol de carpetas relevante

```
app-shell-maxx/
├── lib/
│   ├── main.dart                 # Entrada, MultiProvider, AuthWrapper, MaterialApp
│   ├── api.dart                  # ApiConfig (HTTP, baseUrl, idSession, parseResponse, etc.)
│   ├── api/
│   │   ├── auth_api.dart         # Login, logout, verifyPassword, forgot/reset password, verify OTP, refresh, me, updateLastLogin
│   │   ├── user_api.dart         # ChangePassword, getUserAddress, influencers/managers, updateUserWithImage (multipart)
│   │   ├── gifts_api.dart        # getGifts, getGiftById, redeemGift, getRedeemHistory, getCategories
│   │   ├── points_api.dart       # getCurrentPoints, getMyPoints, getPointsHistory, redeemProduct, claimBirthdayBonus, etc.
│   │   ├── notifications_api.dart# Obtener y marcar notificaciones como leídas
│   │   └── README.md
│   ├── contexts/
│   │   ├── points_provider.dart  # Estado global de puntos + caché
│   │   └── products_provider.dart# Estado global de productos + caché
│   ├── layouts/
│   │   └── main_layout.dart      # Scaffold con PageView (Gifts, Home, Profile) + CustomBottomNav
│   ├── models/
│   │   ├── api_response.dart    # ApiResponse<T> (success, message, data, rawData)
│   │   ├── user_model.dart      # UserModel (id, name, email, type, roleId, profileImage, ...)
│   │   ├── product_model.dart   # ProductModel, ProductRoute; localImagePath por nombre
│   │   └── notification_model.dart # Modelo para notificaciones (NotificationModel)
│   ├── pages/
│   │   ├── intro/               # intro_page.dart (splash → Login)
│   │   ├── auth/                # login, loading_video, forgot_password, verify_code, reset_password
│   │   ├── onboarding/          # onboarding_page.dart
│   │   ├── home/                # home.dart (ClubShellHome)
│   │   ├── gifts/               # gifts_page, product_detail_page, redeem_success_page
│   │   ├── notifications/       # notifications_page.dart
│   │   └── profile/             # profile_page, addresses, redeemed_prizes, managers, influencers, help, privacy, change_password, earn_extra_points_page, trivia_futbolera_page, etc.
│   ├── services/
│   │   ├── auth_service.dart    # Singleton: isLoggedIn, getCurrentUser, login, logout, updateUser, notifySessionExpired
│   │   └── birthday_service.dart# Lógica para mostrar bono de cumpleaños anual
│   ├── theme/
│   │   ├── app_colors.dart       # Colores Shell (primary, secondary, success, error, etc.)
│   │   └── app_theme.dart        # lightTheme, darkTheme (Material 3, Shell)
│   ├── utils/
│   │   └── failed_image_cache.dart # Set de URLs de imágenes fallidas (evitar reintentos)
│   └── widgets/
│       ├── custom_bottom_nav.dart  # Barra inferior 3 tabs (Regalos, Home, Perfil)
│       ├── product_card.dart       # Card de producto con imagen, puntos, botón Canjear
│       ├── birthday_popup.dart     # Popup de feliz cumpleaños
│       └── session_expired_popup.dart # Popup de sesión expirada
├── assets/
│   ├── images/                  # app, brand, carrousel, products, icons
│   └── videos/                  # animationShell.mp4
├── fonts/                       # Shell* (Light, Book, Medium, Bold, Heavy, Condensed, etc.)
├── android/                     # build.gradle.kts, key.properties, namespace com.shellmaxx.app
├── ios/                         # Runner, Info.plist, orientaciones
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Separación de responsabilidades

| Carpeta     | Responsabilidad |
|------------|------------------|
| **api/**   | Llamadas HTTP por dominio (auth, user, gifts, points). Sin estado. |
| **contexts/** | Estado global (puntos, productos) y caché en SharedPreferences. |
| **layouts/**  | Composición de pantallas principales (MainLayout con PageView de 3 páginas). |
| **models/**   | Modelos de datos y serialización JSON (ApiResponse, UserModel, ProductModel, NotificationModel). |
| **pages/**    | Pantallas completas y flujos (auth, onboarding, home, gifts, profile, notifications). |
| **services/** | Lógica de negocio reutilizable (auth, sesión, birthday). |
| **theme/**    | Colores y tema Material (AppColors, AppTheme). |
| **widgets/**  | Componentes reutilizables (bottom nav, product card). |
| **utils/**    | Utilidades (p. ej. caché de URLs de imágenes fallidas). |

---

## Módulos principales y cómo añadir una nueva pantalla o funcionalidad

### Añadir una nueva pantalla

1. Crear el archivo en `lib/pages/<flujo>/<nombre>_page.dart` (p. ej. `lib/pages/profile/nueva_pantalla_page.dart`).
2. Implementar un `StatefulWidget` o `StatelessWidget` que reciba los parámetros necesarios (p. ej. `UserModel user` si requiere usuario).
3. Navegar desde el origen con `Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevaPantallaPage(...)));`.
4. Si la pantalla debe aparecer en el menú del perfil, añadir un ítem en `lib/pages/profile/profile_page.dart` que haga el `push` a la nueva página.

### Añadir un nuevo endpoint o dominio de API

1. Añadir métodos estáticos en el `*_api.dart` correspondiente (o crear uno nuevo en `lib/api/`) usando `ApiConfig.getResponse`, `postResponse`, etc.
2. Usar `ApiResponse<T>` y, si aplica, un modelo en `lib/models/` con `fromJson`/`toJson`.
3. Llamar al nuevo método desde la página o el provider que lo necesite.

### Añadir estado global (nuevo Provider)

1. Crear un nuevo `ChangeNotifier` en `lib/contexts/` (p. ej. `nuevo_provider.dart`).
2. Registrarlo en `main.dart` dentro de `MultiProvider(providers: [...])`.
3. Consumirlo en las pantallas con `context.read<NuevoProvider>()` o `Consumer<NuevoProvider>`.

---

## Patrones de diseño utilizados

| Patrón | Uso en el proyecto |
|--------|---------------------|
| **Singleton** | `AuthService.instance` para acceso global al estado de autenticación. |
| **Provider (ChangeNotifier)** | `PointsProvider` y `ProductsProvider` para estado global reactivo con caché. |
| **Configuración centralizada** | `ApiConfig` en `api.dart`: baseUrl, headers, idSession, métodos HTTP y parseo de respuestas. |
| **Módulos por dominio** | `AuthApi`, `UserApi`, `GiftsApi`, `PointsApi` agrupan endpoints por ámbito. |
| **Modelo de respuesta estándar** | `ApiResponse<T>` unifica éxito/error, mensaje y datos; soporta formato legacy `status`/`message`/`data`. |
| **Navegación imperativa** | `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil` con `MaterialPageRoute`; no hay rutas nombradas ni GoRouter. |

No se usa inyección de dependencias (get_it, etc.), ni capa de repositorios ni casos de uso explícitos.
