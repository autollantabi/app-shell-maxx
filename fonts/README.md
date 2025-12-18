# Cómo Añadir Fuentes Personalizadas

## Instrucciones para añadir fuentes al proyecto

### 1. Descargar las fuentes

- Descarga el archivo de fuente Shell Heavy desde el sitio oficial de Shell
- Necesitarás este archivo:
  - `Shell-Heavy.ttf`

### 2. Colocar los archivos

- Coloca el archivo `.ttf` en la carpeta `fonts/` del proyecto
- La estructura debe quedar así:
  ```
  fonts/
  └── Shell-Heavy.ttf
  ```

### 3. Configurar pubspec.yaml

El archivo `pubspec.yaml` ya está configurado con:

```yaml
fonts:
  - family: Shell Heavy
    fonts:
      - asset: fonts/Shell-Heavy.ttf
```

### 4. Usar en el código

La fuente ya está configurada como fuente principal en `app_theme.dart`:

```dart
fontFamily: 'Shell Heavy',
```

### 5. Ejecutar flutter pub get

Después de añadir los archivos de fuente, ejecuta:

```bash
flutter pub get
```

### 6. Hot restart

Para que los cambios de fuente se apliquen, necesitas hacer un hot restart completo de la aplicación:

- Presiona `R` (mayúscula) en la terminal
- O detén la app y vuelve a ejecutar `flutter run`

## Notas importantes

- Las fuentes personalizadas requieren hot restart (no hot reload)
- Asegúrate de que los nombres de archivo coincidan exactamente
- Las fuentes deben estar en formato `.ttf` o `.otf`
- Shell Heavy es la fuente oficial de la marca Shell
