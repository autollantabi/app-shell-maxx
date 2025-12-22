import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../api/points_api.dart';
import '../../api.dart';
import '../../api/gifts_api.dart';
import '../../contexts/points_provider.dart';

class RedeemedPrize {
  final String id;
  final String name;
  final String imageUrl;
  final String redeemedDate;
  final int points;
  final bool isAvailable;
  final String?
  productId; // ID del producto para comparar con productos disponibles

  RedeemedPrize({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.redeemedDate,
    required this.points,
    required this.isAvailable,
    this.productId,
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
              print(
                'Producto cargado en mapa: ID=$productId, IS_ACTIVE=${product['IS_ACTIVE'] ?? product['isActive']}',
              );
            }
          }
        }

        print('Total productos disponibles cargados: ${productsMap.length}');
        if (mounted) {
          setState(() {
            _availableProducts = productsMap;
          });
        }
      }
    } catch (e) {
      print('Error al cargar productos disponibles: $e');
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
      print('Error al cargar puntos disponibles: $e');
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
    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await PointsApi.getMyRedemptions();

      print('=== LOAD REDEMPTIONS - /canjes/mis-canjes ===');
      print('apiResponse.success: ${apiResponse.success}');
      print('apiResponse.message: ${apiResponse.message}');
      print('apiResponse.data: ${apiResponse.data}');
      print('=============================================');

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
              final pointsRedeemed = canje['POINTS_REDEEMED'] as int? ?? 0;
              final canjeId = canje['ID']?.toString() ?? '';
              final productId =
                  producto?['ID']?.toString() ?? producto?['id']?.toString();

              print(
                'Procesando canje: productId=$productId, nombre=$productName',
              );
              print(
                'Productos disponibles en mapa: ${_availableProducts.keys.toList()}',
              );

              // Buscar el producto en los productos disponibles para verificar su estado actual
              bool isActive = false;
              int currentProductPoints = pointsRedeemed;

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

                currentProductPoints =
                    availableProduct['POINTS'] as int? ??
                    availableProduct['points'] as int? ??
                    pointsRedeemed;

                print(
                  'Producto encontrado en disponibles: ID=$productId, IS_ACTIVE disponible=$availableIsActive, IS_ACTIVE canje=$canjeIsActive, final=$isActive, POINTS=$currentProductPoints',
                );
              } else {
                // Si no se encuentra en productos disponibles, verificar en el producto del canje
                final canjeIsActive = getIsActiveFromProduct(producto);

                // Si no se puede determinar desde el canje, asumir activo por defecto
                // (el producto puede estar activo pero simplemente no estar en la lista cargada)
                isActive = canjeIsActive ?? true;

                print(
                  'Producto NO encontrado en disponibles: ID=$productId, usando IS_ACTIVE del canje=$canjeIsActive, asumiendo isActive=$isActive',
                );
              }

              final imageUrl = _getProductImageUrl(producto) ?? '';

              prizes.add(
                RedeemedPrize(
                  id: canjeId,
                  name: productName,
                  imageUrl: imageUrl,
                  redeemedDate: _formatDate(redemptionDate),
                  points: currentProductPoints,
                  isAvailable: isActive,
                  productId: productId,
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
          print('Error al cargar canjes: ${apiResponse.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error al cargar canjes: $e');
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
            fontFamily: 'ShellBold',
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
          ? _buildEmptyState()
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

                return ListView.separated(
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
                ? ClipRRect(
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
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.name,
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
                      prize.points.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'ShellBold',
                        color: AppColors.textPrimary,
                      ),
                    ),
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

  void _handleRedeemAgain(RedeemedPrize prize) {
    // TODO: Implementar lógica para canjear nuevamente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Canjeando ${prize.name}...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
