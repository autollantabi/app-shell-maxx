# Despliegue y builds

Proceso de build, configuración de entornos y consideraciones para producción del proyecto Shell Maxx.

---

## Proceso de build

### Comandos básicos

| Objetivo | Comando |
|----------|---------|
| Ejecutar en modo debug (dispositivo/emulador) | `flutter run` |
| Build APK debug | `flutter build apk --debug` |
| Build APK release | `flutter build apk --release` |
| Build App Bundle (recomendado para Play Store) | `flutter build appbundle --release` |
| Build iOS | `flutter build ios` (luego abrir Xcode para archivar y subir) |

### Salidas generadas

- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk` (o `app-debug.apk` en debug).
- **Android AAB**: `build/app/outputs/bundle/release/app-release.aab`.
- **iOS**: producto en `build/ios/`; para distribución se usa Xcode (Archive → Distribute App).

---

## Configuración de ambientes

El proyecto **no define flavors** (dev/staging/prod). La única variación por ambiente es la **URL base de la API**:

| Modo | Cómo se elige | URL base |
|------|----------------|----------|
| Debug | `flutter run` o ejecución desde IDE en modo debug | `https://api.maxximundo.com/api/app-shell/dev` |
| Release | `flutter build apk --release` o `flutter build appbundle --release` | `https://api.maxximundo.com/api/app-shell` |

La detección se hace en `lib/api.dart` con `kDebugMode`. Para forzar otra URL en debug (p. ej. apuntar a producción), se puede llamar al inicio:

```dart
ApiConfig.setBaseUrl('https://api.maxximundo.com/api/app-shell');
```

No hay archivos `.env` ni variables de entorno de compilación documentadas.

---

## Android: consideraciones para producción

### Versión y nombre

- **applicationId**: `com.shellmaxx.app` (en `android/app/build.gradle.kts`).
- **versionCode / versionName**: los toma Flutter desde `pubspec.yaml` (version: 1.0.0+4 → versionName 1.0.0, versionCode 4).
- **Nombre visible**: "Shell Maxx" (resValue en build.gradle y AndroidManifest).

### Firma de release

- El build de **release** usa una configuración de firma definida en `android/app/build.gradle.kts` (signingConfigs "release").
- Requiere el archivo **key.properties** en la carpeta `android/` (no está en el repositorio). Si no existe, el release se firma con la configuración debug.
- Pasos para generar keystore y configurar firma: **[android/FIRMA_APP.md](../android/FIRMA_APP.md)**.
- Contenido típico de `key.properties`:
  - `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (ruta al .jks).
- **No subir** `key.properties` ni el archivo `.jks` al repositorio (deben estar en `.gitignore`).

### Permisos

- En el código revisado solo se usan INTERNET y ACCESS_NETWORK_STATE; el resto depende del contenido del AndroidManifest y de plugins (p. ej. image_picker para cámara/almacenamiento).

### Build release Android (resumen)

1. Crear keystore y `key.properties` según FIRMA_APP.md.
2. Ejecutar: `flutter build appbundle --release` (recomendado para Play Store) o `flutter build apk --release`.
3. Verificar firma si se desea: `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`.

---

## iOS: consideraciones para producción

### Configuración en Xcode

- Abrir **ios/Runner.xcworkspace** (no el .xcodeproj).
- Seleccionar el target **Runner** y configurar:
  - **Signing & Capabilities**: Team, Bundle Identifier (debe coincidir con el perfil de aprovisionamiento).
  - **General**: versión y build si se quieren sobrescribir.
- Para dispositivo físico y distribución (TestFlight/App Store) son necesarios certificados de distribución y perfil de aprovisionamiento válidos.

### Info.plist

- **CFBundleDisplayName**: "Shell Maxx".
- Orientaciones: portrait y landscape (según configuración actual).
- **NSAppTransportSecurity**: en el código revisado se permite carga arbitraria (NSAllowsArbitraryLoads) para desarrollo; en producción conviene restringir solo a los dominios necesarios (p. ej. api.maxximundo.com).

### Build release iOS (resumen)

1. Configurar signing y Bundle ID en Xcode.
2. `flutter build ios` (o compilar desde Xcode).
3. En Xcode: Product → Archive → Distribute App (App Store Connect, TestFlight, etc.).

---

## Consideraciones para producción

- **API**: en release la app usa `https://api.maxximundo.com/api/app-shell`. Asegurar que el backend de producción está estable y que los certificados SSL son válidos.
- **Sesión**: el `id-session` se guarda en SharedPreferences; no está cifrado. Para mayor seguridad se podría migrar a flutter_secure_storage (ver [pendientes.md](pendientes.md)).
- **Caché**: puntos y productos se cachean 1 hora; en producción puede ser aceptable; si se requiere datos más frescos, valorar reducir TTL o forzar refresh en momentos clave.
- **Errores y logs**: los `debugPrint` no aparecen en release; no hay integración de crash reporting o analytics documentada en el código; se puede añadir según política del equipo.
- **Actualizaciones**: la app usa `package_info_plus`; no se ha revisado si se usa para forzar actualización o mostrar versión en pantalla; útil para soporte en producción.

---

## Resumen de salidas y referencias

| Plataforma | Salida principal | Referencia |
|------------|------------------|------------|
| Android (store) | AAB en `build/app/outputs/bundle/release/` | [FIRMA_APP.md](../android/FIRMA_APP.md) |
| Android (instalación directa) | APK en `build/app/outputs/flutter-apk/` | Mismo signing que AAB |
| iOS | Archive desde Xcode | Certificados y perfiles en Apple Developer |
