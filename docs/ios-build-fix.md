# Solución: errores al construir iOS (Flutter/Flutter.h not found)

## Causa
Los errores aparecen porque Xcode no encuentra los headers de Flutter al compilar el plugin `package_info_plus`. Suele pasar cuando:
- Se abre o se construye el proyecto directamente en Xcode sin usar Flutter antes.
- Se abre el `.xcodeproj` en lugar del `.xcworkspace`.
- Los Pods o la configuración generada por Flutter están desactualizados.

## Pasos para solucionar

### 1. Limpiar y regenerar
En la raíz del proyecto (donde está `pubspec.yaml`):

```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd ..
```

### 2. Construir desde Flutter (recomendado)
Siempre que sea posible, genera el build de iOS con Flutter:

```bash
flutter build ios
```

Luego puedes abrir el workspace en Xcode para firmar o archivar:

```bash
open ios/Runner.xcworkspace
```

**Importante:** abre `Runner.xcworkspace`, no `Runner.xcodeproj`.

### 3. Si necesitas construir desde Xcode
- Abre **siempre** `ios/Runner.xcworkspace` (no el .xcodeproj).
- Antes de abrir Xcode, ejecuta al menos una vez desde la raíz del proyecto:
  ```bash
  flutter pub get
  cd ios && pod install && cd ..
  ```

### 4. Si sigue fallando: excluir RunnerTests del build
El target **RunnerTests** a veces hace que Xcode intente compilar los Pods en un contexto donde no está definido `FLUTTER_ROOT`. Si el error persiste:

- En Xcode: **Product → Scheme → Edit Scheme…**
- En la pestaña **Build**, en la lista de targets, **desmarca** "RunnerTests" para que no se construya al hacer Build.
- Deja solo "Runner" marcado.

Así evitas que se compile el target de tests (que hereda los Pods) hasta que Flutter/Xcode resuelvan bien los paths.

## Resumen
1. `flutter clean` → `flutter pub get` → `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update`
2. Usar `flutter build ios` para compilar.
3. Abrir siempre `Runner.xcworkspace`.
4. Si hace falta, quitar RunnerTests del scheme de Build.
