# Pendientes y mejoras

Mejoras técnicas sugeridas, deuda técnica detectada y suposiciones o partes no claras del proyecto. Sirve como backlog de mejoras para quien mantenga el código.

---

## Mejoras técnicas sugeridas

1. **Arquitectura**
   - Introducir una capa de casos de uso o repositorios para desacoplar la UI de la API y mejorar testabilidad.
   - Valorar inyección de dependencias (get_it, etc.) para facilitar tests y sustitución de implementaciones.

2. **Navegación**
   - Migrar a **GoRouter** (o rutas declarativas) para deep links, rutas nombradas consistentes y pruebas de flujos.
   - Corregir o unificar el uso de `Navigator.pushNamedAndRemoveUntil('/', (route) => false)` en `profile_page.dart` y `redeem_success_page.dart`: el `MaterialApp` actual no define `routes`, por lo que `'/'` depende del comportamiento por defecto del `home`. Preferible usar `MaterialPageRoute(builder: (_) => AuthWrapper())` o definir rutas explícitas.

3. **Seguridad**
   - Valorar **flutter_secure_storage** (o equivalente) para almacenar `idSession` y datos sensibles en lugar de SharedPreferences.
   - Revisar en iOS la configuración de **NSAppTransportSecurity** en Info.plist; en producción restringir solo a los dominios necesarios (p. ej. api.maxximundo.com) en lugar de NSAllowsArbitraryLoads.

4. **Testing**
   - Añadir tests unitarios para **PointsProvider**, **ProductsProvider** y **AuthService** (login, logout, parsing de usuario).
   - Añadir tests de integración o widget para flujos críticos: login, canje de producto, recuperación de contraseña.
   - El `test/widget_test.dart` actual es el contador por defecto de Flutter; adaptarlo o sustituirlo por tests útiles para la app.

5. **UX y consistencia**
   - Unificar estados de carga y error (indicadores, mensajes) en las pantallas que llaman a la API.
   - Centralizar mensajes de error (y si aplica traducciones) en un único lugar para mantener coherencia.

6. **Mantenibilidad**
   - Reducir duplicación de lógica “obtener userData de ApiResponse” (rawData/data/usuarioData) en un helper o extensión reutilizable.
   - Documentar o normalizar el contrato de respuesta del backend (nombres de campos, estructura) para reducir variantes de parsing en el cliente.

7. **Rendimiento**
   - Si el catálogo crece mucho: valorar listas lazy o paginación en productos; el backend ya soporta `page` y `limit` en GET `/productos`.
   - Valorar **cached_network_image** (o similar) para imágenes de red si no está ya cubierto y hay problemas de rendimiento o datos.

---

## Deuda técnica detectada

| Área | Descripción |
|------|-------------|
| **Rutas** | Uso de `pushNamedAndRemoveUntil('/', ...)` sin rutas nombradas definidas en MaterialApp. |
| **Parsing API** | Múltiples variantes (data, rawData, usuarioData, MAYÚSCULAS) repartidas en AuthService, ProfilePage, providers; frágil ante cambios del backend. |
| **Roles** | Mezcla de `UserType` (admin/manager/influencer) y `roleId` (1/2/3) e isManagerByRole/isVendedorByRole; conviene un criterio único para permisos en la UI. |
| **Canje** | Dos vías: PointsApi.redeemProduct (/canjes) como principal y GiftsApi.redeemGift (/gifts/redeem); asegurar que no queden flujos huérfanos o inconsistentes. |
| **Tests** | Casi inexistentes; cualquier refactor o cambio de API tiene riesgo alto. |
| **Sesión** | Almacenada en claro en SharedPreferences; sin refresh token (requiere login manual al expirar). |

---

## Suposiciones o partes no claras

1. **Backend**: no hay documentación OpenAPI/Swagger en el repo; los endpoints y formatos de respuesta se han inferido del código. Cualquier cambio de contrato en la API puede requerir ajustes en varios archivos.

2. **Registro de usuarios**: AuthApi expone `register`; no se ha verificado si la app permite registro desde la UI o si es solo para uso interno/otras apps.

3. **Refresh token**: existe el endpoint `/auth/refresh-token` en auth_api.dart; no hay uso en el flujo de login ni interceptors que renueven la sesión. **Suposición**: o no se usa o está previsto para una fase posterior.

4. **Package info**: `package_info_plus` está en dependencias; el uso concreto (versión en pantalla, forzar actualización) no se ha revisado en detalle.

5. **Historial de puntos**: PointsApi.getPointsHistory usa `/points/history`; en el proyecto se eliminó `points_history_page.dart` (según git status). **Suposición**: la funcionalidad se retiró o se movió; si se vuelve a ofrecer, hará falta una pantalla que consuma ese endpoint.

6. **Web y escritorio**: la estructura Flutter para web, macOS, Windows y Linux existe pero no está documentada como objetivo del proyecto; se asume que el foco es Android e iOS.

7. **Contacto / responsable**: no hay referencia en el repositorio a un mantenedor o equipo de contacto; conviene añadirla en README o en esta guía si el equipo lo define.

---

## Priorización sugerida (orientativa)

- **Alta**: corregir navegación post-logout y post-canje (rutas o reemplazo de `pushNamedAndRemoveUntil('/')`), y añadir tests básicos para login y providers.
- **Media**: almacenamiento seguro de sesión, unificación de parsing de respuestas, documentar contrato de API con el equipo backend.
- **Baja**: migración a GoRouter, capa de repositorios, paginación de productos, cached_network_image.

Este documento puede actualizarse conforme se resuelvan ítems o se detecten nuevos.
