/// Cache de URLs de imágenes que fallaron al cargar (404, etc.).
/// Evita llamar a Image.network de nuevo para esas URLs y así no repetir
/// excepciones en consola.
class FailedImageCache {
  static final Set<String> _failed = {};

  static bool isFailed(String url) => url.isNotEmpty && _failed.contains(url);

  static void addFailed(String url) {
    if (url.isNotEmpty) _failed.add(url);
  }
}
