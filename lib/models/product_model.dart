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

class SpecificationModel {
  final String id;
  final String name;
  final List<String> values; // Tallas disponibles, ej. ["XS", "S", "M", ...]

  SpecificationModel({
    required this.id,
    required this.name,
    this.values = const [],
  });

  factory SpecificationModel.fromJson(Map<String, dynamic> json) {
    // Parsear los valores (tallas). Cada valor puede venir como {VALUE, SORT_ORDER}
    // o como string simple. Se ordena por SORT_ORDER cuando está disponible.
    final rawValues = json['VALUES'] ?? json['values'];
    final List<Map<String, dynamic>> parsed = [];
    if (rawValues is List) {
      for (final v in rawValues) {
        if (v is Map<String, dynamic>) {
          final value = (v['VALUE'] ?? v['value'] ?? '').toString();
          if (value.isEmpty) continue;
          final sortRaw = v['SORT_ORDER'] ?? v['sort_order'];
          final sort = sortRaw != null
              ? int.tryParse(sortRaw.toString()) ?? 0
              : 0;
          parsed.add({'value': value, 'sort': sort});
        } else if (v != null) {
          final value = v.toString();
          if (value.isNotEmpty) {
            parsed.add({'value': value, 'sort': parsed.length});
          }
        }
      }
    }
    parsed.sort(
      (a, b) => (a['sort'] as int).compareTo(b['sort'] as int),
    );

    return SpecificationModel(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      name: (json['NAME'] ?? json['name'] ?? '').toString(),
      values: parsed.map((e) => e['value'] as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'values': values};
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int points;

  /// Cantidad de productos en este canje (informativo, no stock).
  final int? quantity;
  final String? imagePath; // RUTA (legacy)
  final List<ProductRoute> routes; // ROUTES con {id, path, url}

  /// Especificación (talla) asignada al producto. Null si no requiere talla.
  final SpecificationModel? specification;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Obtiene la ruta de la imagen local basada en el nombre del producto
  String? get localImagePath {
    return null;
  }

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.points,
    this.quantity,
    this.imagePath,
    this.routes = const [],
    this.specification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['ID'] ?? json['id'] ?? '';
    final name = json['NAME'] ?? json['name'] ?? '';
    final description = json['DESCRIPTION'] ?? json['description'] ?? '';
    final category = json['CATEGORY'] ?? json['category'] ?? '';
    final points = json['POINTS'] ?? json['points'] ?? 0;
    final quantityRaw = json['QUANTITY'] ?? json['quantity'];
    final quantity = quantityRaw != null
        ? int.tryParse(quantityRaw.toString())
        : null;
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

    // Parsear especificación (talla) si viene asignada al producto
    SpecificationModel? specification;
    final specData = json['SPECIFICATION'] ?? json['specification'];
    if (specData is Map<String, dynamic>) {
      specification = SpecificationModel.fromJson(specData);
      // Ignorar especificaciones sin tallas disponibles
      if (specification.values.isEmpty) {
        specification = null;
      }
    }

    return ProductModel(
      id: id,
      name: name,
      description: description,
      category: category,
      points: points is int ? points : int.tryParse(points.toString()) ?? 0,
      quantity: quantity,
      imagePath: imagePath,
      routes: routes,
      specification: specification,
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
      if (quantity != null) 'quantity': quantity,
      'ruta': imagePath,
      'routes': routes.map((route) => route.toJson()).toList(),
      if (specification != null) 'specification': specification!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
