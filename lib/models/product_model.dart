class ProductRoute {
  final String id;
  final String? path;
  final String? url;

  ProductRoute({required this.id, this.path, this.url});

  factory ProductRoute.fromJson(Map<String, dynamic> json) {
    return ProductRoute(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      path: json['path']?.toString() ?? json['PATH']?.toString(),
      url: json['url']?.toString() ?? json['URL']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'path': path, 'url': url};
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int points;
  final String? imagePath; // RUTA (legacy)
  final List<ProductRoute> routes; // ROUTES con {id, path, url}
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Obtiene la ruta de la imagen local basada en el nombre del producto
  String? get localImagePath {
    final nameLower = name.toLowerCase();

    // Mapeo de nombres de productos a imágenes locales
    if (nameLower.contains('camiseta') || nameLower.contains('ferrari')) {
      return 'assets/images/products/camiseta.png';
    } else if (nameLower.contains('llavero')) {
      return 'assets/images/products/llavero.png';
    } else if (nameLower.contains('kfc')) {
      return 'assets/images/products/bonokfc.png';
    } else if (nameLower.contains('favorito')) {
      return 'assets/images/products/bonofavorito.png';
    } else if (nameLower.contains('comisariato') ||
        nameLower.contains('mi comisariato')) {
      return 'assets/images/products/bonomicomisariato.png';
    } else if (nameLower.contains('cube')) {
      return 'assets/images/products/bonocube.png';
    } else if (nameLower.contains('microondas')) {
      return 'assets/images/products/microondas.png';
    } else if (nameLower.contains('televisión') ||
        nameLower.contains('television') ||
        nameLower.contains('tv')) {
      return 'assets/images/products/television.png';
    } else if (nameLower.contains('cafetera')) {
      return 'assets/images/products/cafetera.png';
    } else if (nameLower.contains('dispensador')) {
      return 'assets/images/products/dispensador.png';
    } else if (nameLower.contains('auto') ||
        nameLower.contains('autito') ||
        nameLower.contains('miniauto')) {
      return 'assets/images/products/miniauto.png';
    } else if (nameLower.contains('gorra')) {
      return 'assets/images/products/gorra.png';
    }

    return null;
  }

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.points,
    this.imagePath,
    this.routes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['ID'] ?? json['id'] ?? '';
    final name = json['NAME'] ?? json['name'] ?? '';
    final description = json['DESCRIPTION'] ?? json['description'] ?? '';
    final category = json['CATEGORY'] ?? json['category'] ?? '';
    final points = json['POINTS'] ?? json['points'] ?? 0;
    final imagePath = json['RUTA'] ?? json['ruta'] ?? json['imagePath'];

    // Parsear ROUTES
    List<ProductRoute> routes = [];
    if (json['ROUTES'] != null || json['routes'] != null) {
      final routesData = json['ROUTES'] ?? json['routes'];
      if (routesData is List) {
        routes = routesData
            .map(
              (route) => ProductRoute.fromJson(
                route is Map<String, dynamic> ? route : {},
              ),
            )
            .where((route) => route.id.isNotEmpty)
            .toList();
      }
    }

    return ProductModel(
      id: id,
      name: name,
      description: description,
      category: category,
      points: points is int ? points : int.tryParse(points.toString()) ?? 0,
      imagePath: imagePath,
      routes: routes,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'points': points,
      'ruta': imagePath,
      'routes': routes.map((route) => route.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
