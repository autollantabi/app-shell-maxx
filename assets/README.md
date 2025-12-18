# Assets del Proyecto

## Estructura de Carpetas

```
assets/
└── images/
    ├── brand/      # Imágenes de la marca Shell
    └── app/        # Imágenes de la aplicación
```

## 📤 Cómo Añadir Imágenes

### 1. Coloca tus archivos

- **Marca** (`brand/`): Logo de Shell, iconos corporativos
- **App** (`app/`): Productos, capturas de pantalla, imágenes de UI

### 2. Ejecuta para actualizar

```bash
flutter pub get
```

### 3. Reinicia la app si está corriendo

## 💻 Uso en el Código

```dart
// Logo de Shell
Image.asset('assets/images/brand/logo_shell.png')

// Producto del catálogo
Image.asset('assets/images/app/producto.jpg')

// Con tamaño específico
Image.asset(
  'assets/images/brand/shell_icon.png',
  width: 50,
  height: 50,
  fit: BoxFit.contain,
)
```

## 📝 Formatos Recomendados

- **PNG**: Logos, iconos (con transparencia)
- **JPG**: Fotografías de productos
- **WebP**: Imágenes optimizadas (menor peso)

## ⚠️ Importante

- Los archivos ya están declarados en `pubspec.yaml`
- Después de añadir imágenes, ejecuta `flutter pub get`
- Si la app está corriendo, reiníciala con hot restart (`Ctrl+Shift+F5`)
