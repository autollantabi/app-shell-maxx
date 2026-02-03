# Shell Maxx (Club Shell Maxx)

## Descripción general

**Shell Maxx** es una aplicación móvil de lealtad para el programa Club Shell Maxx. Permite a influenciadores, managers y vendedores acumular puntos, consultar su saldo y canjear puntos por productos del catálogo (premios, gift cards, experiencias, etc.).

- **Nombre del paquete**: `app_shell`
- **Identificador de aplicación**: `com.shellmaxx.app` (Android / iOS)

## Problema que resuelve

- Centralizar el acceso al programa de lealtad Shell en el móvil.
- Mostrar puntos disponibles, generados y extra de forma clara.
- Ofrecer un catálogo de productos canjeables por puntos.
- Gestionar perfiles según rol (Manager, Vendedor, Influenciador): managers e influencers, direcciones, canjes, premios canjeados.
- Facilitar el primer acceso: login por email, validación de contraseña, creación de contraseña si no existe, recuperación de contraseña por OTP.

## Tipo de aplicación

- **Plataforma**: aplicación móvil multiplataforma (Flutter).
- **Enfoque**: Android e iOS (orientación portrait). Web y escritorio tienen estructura generada por Flutter pero no son el foco del proyecto.

## Stack tecnológico

| Área | Tecnología |
|------|------------|
| Framework | Flutter (Dart ^3.9.2) |
| Estado global | Provider |
| HTTP | paquete `http` + `ApiConfig` centralizado |
| Persistencia local | SharedPreferences |
| UI | Material 3, fuentes Shell, tema light/dark |
| Otros | image_picker, image_cropper, video_player, package_info_plus |

## Casos de uso principales

1. **Login**: validar email, ingresar o crear contraseña, guardar sesión (`id-session`) y navegar al home o onboarding.
2. **Consultar puntos**: ver puntos disponibles, del mes, acumulados y extra (con caché local).
3. **Ver catálogo**: listar productos por categoría, ver detalle y canjear por puntos.
4. **Canjear producto**: según rol y categoría, con o sin dirección de envío; actualización de puntos tras el canje.
5. **Perfil**: editar avatar, ver direcciones, premios canjeados, managers/influencers (según rol), ayuda, política de privacidad, cambiar contraseña, cerrar sesión.
6. **Recuperar contraseña**: solicitar reset por email, verificar OTP y restablecer contraseña.

## Guía rápida de ejecución

1. Clonar el repositorio y entrar en la carpeta del proyecto.
2. Instalar dependencias: `flutter pub get`.
3. Conectar un dispositivo o iniciar un emulador.
4. Ejecutar: `flutter run`.

Para requisitos del sistema, variables de entorno, pasos detallados y errores comunes, consultar **[docs/setup.md](docs/setup.md)**.

## Documentación

Índice completo de la documentación técnica, orden de lectura recomendado y descripción de cada documento: **[docs/indice.md](docs/indice.md)**.

## Versión

- **Versión**: 1.0.0+4 (definida en `pubspec.yaml`).
