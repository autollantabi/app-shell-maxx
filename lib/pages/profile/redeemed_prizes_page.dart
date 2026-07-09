import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../api/points_api.dart';
import '../../api.dart';
import '../../api/gifts_api.dart';
import '../../contexts/points_provider.dart';
import '../../models/user_model.dart';
import '../../pages/gifts/product_detail_page.dart';
import '../../utils/failed_image_cache.dart';

class RedeemedPrize {
  final String id;
  final String name;
  final String imageUrl;
  final String redeemedDate;
  final int points; // Precio actual del producto
  final int pointsRedeemed; // Puntos que se gastaron en el canje
  final int quantity; // Cantidad de productos canjeados
  final bool isAvailable;
  final String?
  productId; // ID del producto para comparar con productos disponibles
  final String? selectedSpecification; // Talla seleccionada en el canje

  RedeemedPrize({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.redeemedDate,
    required this.points,
    required this.pointsRedeemed,
    required this.quantity,
    required this.isAvailable,
    this.productId,
    this.selectedSpecification,
  });
}

class RedeemedPrizesPage extends StatefulWidget {
  const RedeemedPrizesPage({super.key});

  @override
  State<RedeemedPrizesPage> createState() => _RedeemedPrizesPageState();
}

class _RedeemedPrizesPageState extends State<RedeemedPrizesPage> {
  List<RedeemedPrize> _redeemedPrizes = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _availableProducts =
      {}; // Mapa de productos disponibles por ID
  int _availablePoints = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Primero cargar productos y puntos disponibles
    await Future.wait([_loadAvailableProducts(), _loadAvailablePoints()]);
    // Luego cargar los canjes para poder comparar con productos disponibles
    await _loadRedeemedPrizes();
  }

  Future<void> _refreshData() async {
    // Recargar todos los datos
    await _loadData();
  }

  Future<void> _loadAvailableProducts() async {
    try {
      final apiResponse = await GiftsApi.getGifts();
      if (apiResponse.success && apiResponse.data != null) {
        final Map<String, Map<String, dynamic>> productsMap = {};

        List<dynamic> products = [];
        if (apiResponse.data is List) {
          products = apiResponse.data as List;
        } else if (apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;
          if (data.containsKey('productos') && data['productos'] is List) {
            products = data['productos'] as List;
          } else if (data.containsKey('ID') || data.containsKey('id')) {
            products = [data];
          }
        }

        for (var product in products) {
          if (product is Map<String, dynamic>) {
            final productId = (product['ID'] ?? product['id'] ?? '').toString();
            if (productId.isNotEmpty) {
              productsMap[productId] = product;
            }
          }
        }

        if (mounted) {
          setState(() {
            _availableProducts = productsMap;
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadAvailablePoints() async {
    try {
      if (!mounted) return;
      final pointsProvider = context.read<PointsProvider>();
      if (pointsProvider.availablePoints == 0 && !pointsProvider.isLoading) {
        await pointsProvider.loadPoints();
      }
      if (mounted) {
        setState(() {
          _availablePoints = pointsProvider.availablePoints;
        });
      }
    } catch (e) {
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  String? _getProductImageUrl(Map<String, dynamic>? producto) {
    if (producto == null) return null;

    // Intentar obtener imagen de routes si existe
    if (producto.containsKey('ROUTES') && producto['ROUTES'] is List) {
      final routes = producto['ROUTES'] as List;
      if (routes.isNotEmpty) {
        final firstRoute = routes[0];
        if (firstRoute is Map && firstRoute.containsKey('URL')) {
          final url = firstRoute['URL'] as String?;
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    }

    // Fallback a imagePath si existe
    if (producto.containsKey('IMAGE_PATH')) {
      final imagePath = producto['IMAGE_PATH'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        return '${ApiConfig.baseUrl.replaceAll('/api', '')}/${imagePath.replaceAll('\\', '/')}';
      }
    }

    // Fallback a RUTA si existe (legacy)
    if (producto.containsKey('RUTA')) {
      final ruta = producto['RUTA'] as String?;
      if (ruta != null && ruta.isNotEmpty) {
        return '${ApiConfig.baseUrl.replaceAll('/api', '')}/${ruta.replaceAll('\\', '/')}';
      }
    }

    return null;
  }

  Future<void> _loadRedeemedPrizes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await PointsApi.getMyRedemptions();

      if (mounted) {
        if (apiResponse.success && apiResponse.data != null) {
          final data = apiResponse.data as Map<String, dynamic>;
          final canjes = data['canjes'] as List<dynamic>? ?? [];

          final List<RedeemedPrize> prizes = [];

          for (var canje in canjes) {
            if (canje is Map<String, dynamic>) {
              final producto = canje['PRODUCTO'] as Map<String, dynamic>?;
              final productName =
                  producto?['NAME'] as String? ?? 'Producto sin nombre';
              final redemptionDate = canje['REDEMPTION_DATE'] as String? ?? '';
              
              // Asegurar que pointsRedeemed siempre sea un int válido
              final pointsRedeemedValue = canje['POINTS_REDEEMED'];
              final pointsRedeemed = (pointsRedeemedValue is int)
                  ? pointsRedeemedValue
                  : (pointsRedeemedValue is num)
                      ? pointsRedeemedValue.toInt()
                      : 0;
              
              final canjeId = canje['ID']?.toString() ?? '';
              final productId =
                  producto?['ID']?.toString() ?? producto?['id']?.toString();

              // Buscar el producto en los productos disponibles para verificar su estado actual
              bool isActive = false;
              int currentProductPoints = 0; // Precio actual del producto

              // Función auxiliar para obtener IS_ACTIVE de un producto
              bool? getIsActiveFromProduct(Map<String, dynamic>? prod) {
                if (prod == null) return null;
                final isActiveValue = prod['IS_ACTIVE'] ?? prod['isActive'];
                if (isActiveValue is bool) {
                  return isActiveValue;
                } else if (isActiveValue is int) {
                  return isActiveValue == 1;
                }
                return null;
              }

              if (productId != null &&
                  _availableProducts.containsKey(productId)) {
                final availableProduct = _availableProducts[productId]!;
                // Verificar IS_ACTIVE en el producto disponible
                final availableIsActive = getIsActiveFromProduct(
                  availableProduct,
                );

                // Si no se puede determinar desde el producto disponible, usar el del canje como fallback
                final canjeIsActive = getIsActiveFromProduct(producto);

                // Priorizar el estado del producto disponible, pero si es null, usar el del canje
                // Si ambos son null, asumir activo por defecto
                isActive = availableIsActive ?? canjeIsActive ?? true;

                // Obtener el precio actual del producto
                currentProductPoints =
                    availableProduct['POINTS'] as int? ??
                    availableProduct['points'] as int? ??
                    0;
              } else {
                // Si no se encuentra en productos disponibles, verificar en el producto del canje
                final canjeIsActive = getIsActiveFromProduct(producto);

                // Si no se puede determinar desde el canje, asumir activo por defecto
                // (el producto puede estar activo pero simplemente no estar en la lista cargada)
                isActive = canjeIsActive ?? true;

                // Intentar obtener el precio del producto del canje
                currentProductPoints =
                    producto?['POINTS'] as int? ??
                    producto?['points'] as int? ??
                    0;
              }

              // Calcular la cantidad basándose en POINTS_REDEEMED / precio del producto
              int finalQuantity = 1; // Valor por defecto
              
              if (currentProductPoints > 0 && pointsRedeemed > 0) {
                try {
                  final calculatedQuantity = (pointsRedeemed / currentProductPoints).round();
                  // Asegurar que la cantidad sea al menos 1
                  finalQuantity = calculatedQuantity < 1 ? 1 : calculatedQuantity;
                } catch (e) {
                  // Si hay error en el cálculo, usar 1
                  finalQuantity = 1;
                }
              }

              final imageUrl = _getProductImageUrl(producto) ?? '';

              final selectedSpecification =
                  canje['SELECTED_SPECIFICATION'] as String?;

              prizes.add(
                RedeemedPrize(
                  id: canjeId,
                  name: productName,
                  imageUrl: imageUrl,
                  redeemedDate: _formatDate(redemptionDate),
                  points: currentProductPoints,
                  pointsRedeemed: pointsRedeemed,
                  quantity: finalQuantity,
                  isAvailable: isActive,
                  productId: productId,
                  selectedSpecification:
                      (selectedSpecification != null &&
                          selectedSpecification.isNotEmpty)
                      ? selectedSpecification
                      : null,
                ),
              );
            }
          }

          setState(() {
            _redeemedPrizes = prizes;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Premios canjeados',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _redeemedPrizes.isEmpty
          ? RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(),
                ),
              ),
            )
          : Consumer<PointsProvider>(
              builder: (context, pointsProvider, child) {
                // Actualizar puntos disponibles desde el provider
                final availablePoints = pointsProvider.availablePoints;
                if (availablePoints != _availablePoints && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _availablePoints = availablePoints;
                      });
                    }
                  });
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _redeemedPrizes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      return _buildPrizeItem(_redeemedPrizes[index]);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No has canjeado ningún premio aún',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'ShellTHAI',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeItem(RedeemedPrize prize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: prize.imageUrl.isNotEmpty
                ? (FailedImageCache.isFailed(prize.imageUrl)
                    ? _buildPlaceholderImage()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          prize.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            FailedImageCache.addFailed(prize.imageUrl);
                            return _buildPlaceholderImage();
                          },
                        ),
                      ))
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.quantity > 1
                      ? '${prize.name} '
                      : prize.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'ShellHeavy',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cajeado el ${prize.redeemedDate}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'ShellBook',
                    color: AppColors.textSecondary,
                  ),
                ),
                if (prize.selectedSpecification != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Talla: ${prize.selectedSpecification}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'ShellBook',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      prize.pointsRedeemed.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'ShellHeavy',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (prize.quantity > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(x${prize.quantity})',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'ShellBook',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botón o estado
          SizedBox(
            height: 72,
            child: Center(
              child: Consumer<PointsProvider>(
                builder: (context, pointsProvider, child) {
                  return _buildButtonOrStatus(
                    prize,
                    pointsProvider.availablePoints,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }

  Widget _buildButtonOrStatus(RedeemedPrize prize, int availablePoints) {
    // Si el producto no está disponible
    if (!prize.isAvailable) {
      return const SizedBox(
        width: 120,
        child: Text(
          'Producto ya no disponible',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'ShellHeavy',
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Si el producto está disponible pero no tiene puntos suficientes
    // Usar el precio actual del producto para la comparación
    final hasEnoughPoints = availablePoints >= prize.points;
    final missingPoints = prize.points - availablePoints;

    if (!hasEnoughPoints) {
      return SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.6),
                foregroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Canjear otra vez',
                style: TextStyle(fontSize: 12, fontFamily: 'ShellHeavy'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Te faltan $missingPoints puntos',
              style: const TextStyle(
                fontSize: 9,
                fontFamily: 'ShellBook',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si el producto está disponible y tiene puntos suficientes
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        onPressed: () => _handleRedeemAgain(prize),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Canjear otra vez',
          style: TextStyle(fontSize: 12, fontFamily: 'ShellHeavy'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _handleRedeemAgain(RedeemedPrize prize) async {
    // Obtener el usuario actual desde SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      
      if (userJson == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener la información del usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel.fromJson(userMap);

      // Obtener el producto desde _availableProducts o desde el canje
      Map<String, dynamic>? productData;
      
      if (prize.productId != null && _availableProducts.containsKey(prize.productId)) {
        productData = _availableProducts[prize.productId];
      }

      // Si no está en productos disponibles, intentar obtenerlo desde el API
      if (productData == null && prize.productId != null) {
        try {
          final apiResponse = await GiftsApi.getGifts();
          if (apiResponse.success && apiResponse.data != null) {
            List<dynamic> products = [];
            if (apiResponse.data is List) {
              products = apiResponse.data as List;
            } else if (apiResponse.data is Map<String, dynamic>) {
              final data = apiResponse.data as Map<String, dynamic>;
              if (data.containsKey('productos') && data['productos'] is List) {
                products = data['productos'] as List;
              }
            }

            for (var product in products) {
              if (product is Map<String, dynamic>) {
                final productId = (product['ID'] ?? product['id'] ?? '').toString();
                if (productId == prize.productId) {
                  productData = product;
                  break;
                }
              }
            }
          }
        } catch (e) {
          // Error al obtener producto, continuar con datos disponibles
        }
      }

      // Si aún no tenemos datos del producto, usar los datos del prize
      if (productData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener la información del producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obtener las imágenes del producto
      final List<String> imageUrls = [];
      
      // Intentar obtener imágenes de ROUTES
      if (productData.containsKey('ROUTES') && productData['ROUTES'] is List) {
        final routes = productData['ROUTES'] as List;
        for (var route in routes) {
          if (route is Map && route.containsKey('URL')) {
            final url = route['URL'] as String?;
            if (url != null && url.isNotEmpty) {
              imageUrls.add(url);
            }
          }
        }
      }

      // Fallback a imagePath si no hay ROUTES
      String? fallbackImageUrl;
      if (imageUrls.isEmpty) {
        if (productData.containsKey('IMAGE_PATH')) {
          final imagePath = productData['IMAGE_PATH'] as String?;
          if (imagePath != null && imagePath.isNotEmpty) {
            fallbackImageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}/${imagePath.replaceAll('\\', '/')}';
            imageUrls.add(fallbackImageUrl);
          }
        } else if (productData.containsKey('RUTA')) {
          final ruta = productData['RUTA'] as String?;
          if (ruta != null && ruta.isNotEmpty) {
            fallbackImageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}/${ruta.replaceAll('\\', '/')}';
            imageUrls.add(fallbackImageUrl);
          }
        }
      }

      // Usar la imagen del prize si no hay otras disponibles
      if (imageUrls.isEmpty && prize.imageUrl.isNotEmpty) {
        imageUrls.add(prize.imageUrl);
      }

      // Obtener datos del producto
      final productName = productData['NAME'] as String? ?? 
                          productData['name'] as String? ?? 
                          prize.name;
      final productPoints = productData['POINTS'] as int? ?? 
                            productData['points'] as int? ?? 
                            prize.points;
      final productDescription = productData['DESCRIPTION'] as String? ?? 
                                 productData['description'] as String? ?? 
                                 '';
      final productCategory = productData['CATEGORY'] as String? ?? 
                              productData['category'] as String? ?? 
                              '';
      final productId = (productData['ID'] ?? productData['id'] ?? prize.productId ?? '').toString();

      // Obtener puntos disponibles
      final availablePoints = context.read<PointsProvider>().availablePoints;

      // Navegar a ProductDetailPage y recargar datos cuando se regrese
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              user: user,
              imagePath: imageUrls.isNotEmpty ? imageUrls[0] : '',
              imagePaths: imageUrls.isNotEmpty ? imageUrls : null,
              title: productName,
              points: productPoints,
              description: productDescription,
              category: productCategory,
              availablePoints: availablePoints,
              productId: productId,
            ),
          ),
        );

        // Recargar datos cuando se regrese de ProductDetailPage
        // Esto asegura que se muestren los nuevos canjes
        if (mounted) {
          await _refreshData();
          // También actualizar los puntos del provider
          try {
            await context.read<PointsProvider>().refresh();
          } catch (e) {
            // Error al actualizar puntos, continuar
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
