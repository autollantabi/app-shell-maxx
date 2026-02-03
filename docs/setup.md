# Configuración del entorno (setup)

Guía para configurar el entorno de desarrollo y ejecutar el proyecto Shell Maxx en local.

---

## Requisitos del sistema

| Requisito | Versión o detalle |
|-----------|-------------------|
| **Flutter SDK** | Compatible con Dart ^3.9.2 (ver `pubspec.yaml`). Se recomienda la versión estable más reciente de Flutter. |
| **Dart** | ^3.9.2 |
| **Android** | Android Studio o Android SDK para emulador y builds. `minSdk` y `targetSdk` los define Flutter en `android/app/build.gradle.kts`. |
| **iOS** | Xcode (solo en macOS) para simulador y builds. CocoaPods para dependencias iOS. |
| **Red** | Acceso a `https://api.maxximundo.com` para consumir la API (login, puntos, productos, canjes). |

Comprobar instalación de Flutter:

```bash
flutter doctor
```

Corregir cualquier incidencia que indique (Android licenses, Xcode, etc.) antes de continuar.

---

## Variables de entorno

El proyecto **no utiliza archivo `.env`** ni paquetes como `flutter_dotenv`.

- **URL base de la API**: se define en código según el modo de ejecución:
  - **Debug**: `https://api.maxximundo.com/api/app-shell/dev`
  - **Release**: `https://api.maxximundo.com/api/app-shell`
- Para forzar otra URL en debug (por ejemplo, apuntar a producción desde el IDE), se puede llamar al inicio de la app (p. ej. en `main()` tras `ensureInitialized`):
  - `ApiConfig.setBaseUrl('https://api.maxximundo.com/api/app-shell');`
  - Para volver al comportamiento por defecto: `ApiConfig.resetBaseUrl()`.

No hay variables de entorno documentadas para API keys ni secrets; la autenticación se hace con sesión (`id-session`) devuelta por el backend en el login.

---

## Pasos para ejecutar el proyecto localmente

1. **Clonar el repositorio** (si aplica) y posicionarse en la raíz del proyecto:
   ```bash
   cd app-shell-maxx
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Conectar un dispositivo físico** (USB, modo desarrollador habilitado) **o iniciar un emulador/simulador**:
   - Android: desde Android Studio (AVD Manager) o `flutter emulators` / `flutter emulators --launch <id>`.
   - iOS: abrir simulador desde Xcode o `open -a Simulator`.

4. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```
   O desde el IDE (VS Code/Cursor): F5 o comando "Run" con el dispositivo seleccionado.

5. **Probar contra la API**: la app en debug usará por defecto el entorno `/api/app-shell/dev`. Si el backend requiere credenciales de prueba, deben proporcionarse aparte (no están en el repositorio).

---

## Errores comunes y cómo resolverlos

| Error o síntoma | Causa probable | Solución |
|-----------------|----------------|----------|
| **key.properties missing** (solo en build release Android) | No existe `android/key.properties` para firmar el release. | Crear el archivo desde `android/key.properties.example` y configurar keystore según [android/FIRMA_APP.md](../android/FIRMA_APP.md). No subir `key.properties` ni el `.jks` al repositorio. |
| **API 401 / 403** en peticiones tras login | El `id-session` no se guardó o no se envía en las peticiones. | Comprobar que el login devuelve `idSession` y que `ApiConfig.setIdSession` se llama en `AuthService.login`. Revisar que `ApiConfig.getHeaders(includeAuth: true)` incluye el header `id-session`. |
| **No se puede conectar al servidor** | Sin red, DNS o API caída. | Verificar conectividad a `https://api.maxximundo.com`. Los mensajes amigables vienen de `ApiConfig.handleConnectionError` (timeout, host lookup, etc.). |
| **Rutas nombradas**: `pushNamedAndRemoveUntil('/', ...)` sin efecto o inesperado | En el código actual, `MaterialApp` no define rutas con `routes`; solo usa `home: AuthWrapper`. | La ruta `'/'` en Flutter suele resolverse al `home`, por lo que puede llevar a AuthWrapper. Para evitar ambigüedad, se recomienda usar `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AuthWrapper()), (_) => false)` o definir rutas nombradas en el futuro (ver [pendientes.md](pendientes.md)). |
| **Imágenes de productos no cargan** | URL inválida, CORS o backend que no sirve la imagen. | Revisar que las URLs sean HTTPS. El proyecto usa `FailedImageCache` para no reintentar URLs que ya fallaron; el fallback es imagen local por nombre de producto. |
| **flutter pub get falla** | Red o mirror de pub. | Comprobar conexión y, si aplica, configurar mirror de pub o proxy. |
| **Build iOS falla (signing)** | Certificados o perfil de aprovisionamiento no configurados. | Abrir `ios/Runner.xcworkspace` en Xcode, seleccionar el target Runner y configurar "Signing & Capabilities" (Team, Bundle Identifier). |
| **Análisis / lints** | Reglas de `flutter_lints` o `analysis_options.yaml`. | Ejecutar `flutter analyze` y corregir los avisos; si se quiere relajar alguna regla, editarlo en `analysis_options.yaml`. |

---

## Verificación rápida

Después del setup, comprobar:

- `flutter doctor` sin errores críticos.
- `flutter pub get` sin fallos.
- `flutter run` arranca la app: pantalla de intro (logo Shell) y luego login o MainLayout si ya hay sesión guardada.

Si la API de desarrollo está disponible, probar login con un usuario de prueba para validar el flujo completo.
