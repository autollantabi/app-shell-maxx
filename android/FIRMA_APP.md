# Configuración de Firma para Publicación

## Pasos para configurar la firma de la aplicación

### 1. Generar el Keystore

Ejecuta el siguiente comando en la terminal (en la carpeta `android/app`):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shell_maxx
```
shell_maxx2025
Este comando te pedirá:

- **Contraseña del keystore**: Guárdala de forma segura
- **Contraseña de la clave**: Puede ser la misma o diferente
- **Información personal**: Nombre, organización, ciudad, etc.

**IMPORTANTE**: Guarda estas contraseñas de forma segura. Si las pierdes, no podrás actualizar tu app en Google Play Store.

### 2. Crear el archivo key.properties

Copia el archivo `key.properties.example` a `key.properties` en la carpeta `android/`:

```bash
# En Windows (PowerShell o CMD)
copy android\key.properties.example android\key.properties

# En Mac/Linux
cp android/key.properties.example android/key.properties
```

### 3. Editar key.properties

Abre `android/key.properties` y completa con tus datos:

```properties
storePassword=TU_CONTRASEÑA_DEL_KEYSTORE
keyPassword=TU_CONTRASEÑA_DE_LA_CLAVE
keyAlias=shell_maxx
storeFile=../app/upload-keystore.jks
```

**Nota**: El archivo `key.properties` está en `.gitignore` para no subirlo al repositorio.

### 4. Compilar la app en modo release

Ahora puedes compilar la app con firma de release:

```bash
flutter build appbundle --release
```

O para generar un APK:

```bash
flutter build apk --release
```

El archivo generado estará en:

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Verificar la firma

Para verificar que el APK/AAB está firmado correctamente:

```bash
# Para AAB
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Para APK
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

## Seguridad

- **NUNCA** subas el archivo `upload-keystore.jks` o `key.properties` al repositorio
- Guarda una copia de seguridad del keystore en un lugar seguro
- Si pierdes el keystore, no podrás actualizar tu app en Google Play Store
