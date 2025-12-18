# Sistema de Gestión de Puntos Shell

## Descripción

Aplicación de gestión de puntos por compras realizadas en Shell. Los usuarios acumulan puntos por sus compras externas (no se compra a través de la app) y pueden canjearlos por productos del catálogo.

## Cómo Ejecutar la Aplicación

1. **Instalar dependencias**:

   ```bash
   flutter pub get
   ```

2. **Lanzar el emulador**:

   - Presiona `Ctrl + Shift + P` (o `Cmd + Shift + P` en Mac)
   - Escribe y selecciona: `Flutter: Launch Emulator`
   - Selecciona el emulador de tu preferencia

3. **Ejecutar la aplicación**:

   - Presiona `F5` para ejecutar en modo debug
   - O presiona `Ctrl + Shift + P` y selecciona `Flutter: Run`
   - O ejecuta desde la terminal:
     ```bash
     flutter run
     ```

## Usuarios de Prueba (Locales)

La aplicación incluye usuarios locales para testing sin necesidad de API:

### 🔑 Credenciales de Acceso

#### Administrador

- **Email:** admin@shell.com
- **Password:** admin123
- **Tipo:** Admin (acceso completo)

#### Manager

- **Email:** manager@shell.com
- **Password:** manager123
- **Tipo:** Manager (gestión de influencers)

#### Usuario Normal

- **Email:** user@shell.com
- **Password:** user123
- **Tipo:** Influencer (usuario regular)

## Funcionalidades Implementadas

### ✅ Sistema de Sesión Persistente

- La sesión se mantiene al cerrar y abrir la app
- Logout disponible en la página de perfil
- Verificación automática de sesión al iniciar

### ✅ Navegación

- Intro → Login → Home
- Bottom navigation con 3 pestañas
- Navegación fluida entre secciones

### ✅ Páginas Principales

- **Club Shell Home:** Página principal con scroll horizontal de productos
- **Gifts:** Catálogo con pestañas (Team Shell, Equipa tu PDV, Modo relax)
- **Perfil:** Información del usuario y logout

4. **Iniciar sesión**:
   - Usa las credenciales de prueba (ver sección "Credenciales de Prueba")

## Cómo Añadir Imágenes al Proyecto

### 📁 Estructura de Assets

El proyecto está configurado con la siguiente estructura para imágenes:

```
assets/
└── images/
    ├── brand/      # Imágenes de la marca Shell (logos, iconos corporativos)
    └── app/        # Imágenes de la aplicación (productos, screenshots, UI)
```

### 📤 Subir Imágenes

1. **Coloca tus imágenes** en la carpeta correspondiente:

   - `assets/images/brand/` → Logo de Shell, iconos de marca
   - `assets/images/app/` → Productos, capturas, imágenes de UI

2. **Ejecuta** para actualizar los assets:

   ```bash
   flutter pub get
   ```

3. **Reinicia la app** si está corriendo

### 💻 Usar Imágenes en el Código

```dart
// Imagen de la marca
Image.asset(
  'assets/images/brand/logo_shell.png',
  width: 100,
  height: 100,
)

// Imagen de la aplicación
Image.asset(
  'assets/images/app/producto.jpg',
  fit: BoxFit.cover,
)
```

### 📝 Formatos Soportados

- PNG (recomendado para logos e iconos)
- JPG/JPEG (recomendado para fotografías)
- GIF (animaciones)
- WebP (imágenes optimizadas)

## Organización de Carpetas

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── theme/                    # Sistema de temas y colores
│   ├── app_colors.dart      # Paleta de colores personalizada
│   └── app_theme.dart       # Configuración de temas (claro/oscuro)
├── models/                   # Modelos de datos
│   └── user_model.dart      # Modelo de usuario con tipos
├── services/                 # Servicios y lógica de negocio
│   └── auth_service.dart    # Servicio de autenticación
├── pages/                    # Páginas de la aplicación
│   ├── auth/                # Páginas de autenticación
│   │   └── login_page.dart  # Pantalla de inicio de sesión
│   ├── home/                # Páginas principales
│   │   └── main_page.dart   # Página principal con navegación
│   ├── admin/               # Páginas de administración
│   │   └── admin_page.dart  # Panel de administración
│   ├── user/                # Páginas de usuarios
│   │   └── user_page.dart   # Gestión de usuarios
│   └── profile/             # Páginas de perfil
│       └── profile_page.dart # Perfil de usuario
├── widgets/                  # Widgets reutilizables
│   └── custom_bottom_nav.dart # Barra de navegación personalizada
├── components/              # Componentes UI reutilizables
├── utils/                   # Utilidades y helpers
└── README.md               # Este archivo
```

## Características Implementadas

### 🎨 Sistema de Temas

- Paleta de colores basada en la marca Shell (Rojo #DD1D21 y Amarillo #FBCE07)
- Soporte para tema claro y oscuro
- Colores específicos para cada tipo de usuario
- Interfaz moderna y profesional

### 👤 Sistema de Usuarios Jerárquico

- **Administrador**:
  - Gestiona y registra Managers
  - Ve puntos de todos los usuarios (Managers e Influencers)
  - Gestiona el catálogo de productos
- **Manager**:
  - Registra y gestiona sus Influencers
  - Ve los puntos acumulados de sus Influencers
  - Gestiona canjes de su equipo
- **Influencer**:
  - Ve sus puntos acumulados
  - Canjea productos del catálogo
  - Consulta historial de transacciones

### 🔐 Autenticación

- Pantalla de inicio de sesión moderna y intuitiva
- Validación completa de formularios
- Servicio de autenticación simulado
- Gestión de sesiones de usuario
- Acceso con credenciales predefinidas
- Registro jerárquico: Admin registra Managers, Manager registra Influencers

### 🧭 Navegación

- Barra de navegación inferior personalizada
- Navegación adaptativa según tipo de usuario
- Páginas específicas para cada rol

### 📱 Páginas Principales

**Para Administrador:**

- **Inicio**: Panel con estadísticas generales de puntos y usuarios
- **Admin**: Herramientas de administración del sistema
- **Managers**: Gestión y registro de managers
- **Perfil**: Información personal

**Para Manager:**

- **Inicio**: Vista de influencers y puntos totales de su equipo
- **Influencers**: Lista de influencers, registro y gestión
- **Perfil**: Información personal

**Para Influencer:**

- **Inicio**: Puntos disponibles e historial de transacciones
- **Perfil**: Información personal y datos de contacto

## Credenciales de Prueba

```
Administrador:
- Email: admin@shell.com
- Contraseña: admin123
- Función: Registrar y gestionar Managers

Manager:
- Email: manager@shell.com
- Contraseña: manager123
- Función: Registrar y gestionar Influencers

Influencer:
- Email: influencer@example.com
- Contraseña: influencer123
- Datos: Cédula, fecha de nacimiento, teléfono, dirección
```

## Mejoras Recientes

✅ Sistema de contraseñas temporales para influencers
✅ Registro sin contraseña - se genera automáticamente
✅ Diálogo informativo con contraseña temporal al registrar
✅ Simulación de envío de correo con credenciales
✅ Página de usuarios completamente adaptativa (Admin/Manager)
✅ Puntos individuales variables por influencer
✅ Botones de registro totalmente funcionales
✅ Tema Shell aplicado consistentemente en toda la app

## Próximas Funcionalidades

### Sistema de Puntos

- [ ] Modelo de puntos con transacciones
- [ ] Registro de compras (acumulación de puntos)
- [ ] Sistema de canjes de puntos por productos
- [ ] Historial completo de transacciones

### Catálogo de Productos

- [ ] Catálogo de productos canjeables
- [ ] Detalles de productos con imágenes
- [ ] Filtros y búsqueda de productos
- [ ] Gestión de stock de productos (Admin)

### Gestión de Usuarios

- [ ] Lista completa de Managers (Admin)
- [ ] Lista de Influencers por Manager
- [ ] Edición y eliminación de usuarios
- [ ] Asignación de puntos manual

### Reportes y Estadísticas

- [ ] Dashboard con gráficos de puntos
- [ ] Reportes de canjes realizados
- [ ] Estadísticas de uso por usuario
- [ ] Exportación de reportes a Excel/PDF

### Mejoras Generales

- [ ] Sistema de cambio de contraseña en primer login
- [ ] Envío real de correos electrónicos con credenciales
- [ ] Integración con API real
- [ ] Almacenamiento persistente de sesión
- [ ] Notificaciones push
- [ ] Recuperación de contraseña
