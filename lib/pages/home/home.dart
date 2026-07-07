import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../api/auth_api.dart';
import '../../contexts/products_provider.dart';
import '../../contexts/points_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../services/birthday_service.dart';
import '../../services/points_service.dart';

/// Widget para la lista de productos del home que mantiene el estado vivo
class _HomeProductsList extends StatefulWidget {
  final UserModel user;

  const _HomeProductsList({required this.user});

  @override
  State<_HomeProductsList> createState() => _HomeProductsListState();
}

class _HomeProductsListState extends State<_HomeProductsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, child) {
        if (productsProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (productsProvider.error != null) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Error: ${productsProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // Obtener productos que el usuario puede reclamar (excluyendo los del CARRUSEL)
        final pointsProvider = context.watch<PointsProvider>();
        final availableProducts = productsProvider.products
            .where((p) => p.category.toUpperCase() != 'CARRUSEL')
            .toList();

        final affordableProducts = availableProducts
            .where(
              (product) => product.points <= pointsProvider.availablePoints,
            )
            .toList();

        // Si hay menos de 5 productos que puede reclamar, completar con otros productos
        List<ProductModel> productsToShow = [];

        // Agregar primero los productos que puede reclamar
        productsToShow.addAll(affordableProducts.take(5));

        // Si no hay suficientes productos que puede reclamar, completar con otros
        if (productsToShow.length < 5) {
          final remainingCount = 5 - productsToShow.length;
          final selectedIds = productsToShow.map((p) => p.id).toSet();
          final otherProducts = availableProducts
              .where((product) => !selectedIds.contains(product.id))
              .take(remainingCount)
              .toList();
          productsToShow.addAll(otherProducts);
        }

        // Limitar a máximo 5 productos
        productsToShow = productsToShow.take(5).toList();

        if (productsToShow.isEmpty) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('No hay productos disponibles')),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: productsToShow.length,
            itemBuilder: (context, index) {
              final product = productsToShow[index];
              // Calcular ancho dinámico para que quepan 2 cards sin cortarse
              final screenWidth = MediaQuery.of(context).size.width;
              final paddingHorizontal =
                  16.0 * 2; // Padding del contenedor padre
              final spacing = 12.0; // Espacio entre cards
              final cardWidth = (screenWidth - paddingHorizontal - spacing) / 2;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < productsToShow.length - 1 ? 12 : 0,
                ),
                child: ProductCard(
                  product: product,
                  user: widget.user,
                  width: cardWidth,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ClubShellHome extends StatefulWidget {
  final UserModel user;
  final void Function(UserModel)? onUserUpdated;

  const ClubShellHome({super.key, required this.user, this.onUserUpdated});

  @override
  State<ClubShellHome> createState() => _ClubShellHomeState();
}

class _ClubShellHomeState extends State<ClubShellHome> {
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _currentUser = widget.user;
    _loadUserData();
    _updateLastLogin();
    // Cargar productos y puntos al inicializar solo si no hay datos cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productsProvider = context.read<ProductsProvider>();
      // Solo cargar si no hay productos ya cargados (evitar recargas innecesarias)
      if (productsProvider.products.isEmpty) {
        productsProvider.loadProducts();
      }

      final pointsProvider = context.read<PointsProvider>();
      // Solo cargar puntos si no hay puntos cargados
      if (pointsProvider.availablePoints == 0 && !pointsProvider.isLoading) {
        pointsProvider.loadPoints();
      }
    });
  }

  Future<void> _updateLastLogin() async {
    try {
      final apiResponse = await AuthApi.updateLastLogin(
        userId: _currentUser.id,
      );

      if (!apiResponse.success) {}
    } catch (e) {
      // No mostramos error al usuario, solo lo registramos
    }
  }

  Future<void> _loadUserData() async {
    try {
      final apiResponse = await AuthApi.getCurrentUser();

      if (apiResponse.success && mounted) {
        // Obtener datos del usuario directamente de la respuesta
        // La respuesta de /auth/me viene con los datos directamente en data
        Map<String, dynamic>? userData;

        // Intentar obtener desde apiResponse.data primero (datos directos)
        if (apiResponse.data != null &&
            apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;

          // Verificar si tiene los campos del usuario (ID, NAME, etc.)
          if (data.containsKey('ID') || data.containsKey('id')) {
            userData = data;
          } else if (data.containsKey('usuarioData')) {
            // Fallback: si viene en usuarioData (para compatibilidad)
            userData = data['usuarioData'] as Map<String, dynamic>?;
          }
        }

        // Si no está en data, intentar desde rawData['data']
        if (userData == null && apiResponse.rawData != null) {
          if (apiResponse.rawData!.containsKey('data')) {
            final data = apiResponse.rawData!['data'];
            if (data is Map<String, dynamic>) {
              // Verificar si tiene los campos del usuario directamente
              if (data.containsKey('ID') || data.containsKey('id')) {
                userData = data;
              } else if (data.containsKey('usuarioData')) {
                // Fallback: si viene en usuarioData
                userData = data['usuarioData'] as Map<String, dynamic>?;
              }
            }
          } else if (apiResponse.rawData!.containsKey('usuarioData')) {
            // Fallback directo en rawData
            userData =
                apiResponse.rawData!['usuarioData'] as Map<String, dynamic>?;
          }
        }

        if (userData != null) {
          final updatedUser = UserModel.fromJson(userData);

          // Guardar usuario actualizado en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_session',
            jsonEncode(updatedUser.toJson()),
          );

          setState(() {
            _currentUser = updatedUser;
          });

          
          if (mounted) {
            // Verificar cumpleaños
            BirthdayService.checkAndShowBirthdayGift(
              context,
              updatedUser,
              onRefresh: () {
                if (mounted) {
                  context.read<PointsProvider>().refresh();
                }
              },
            );

            //verificacion de puntos de usuario (regalo de puntos, independiente del cumpleaños)
            PointsService.checkAndShowPointsGift(
              context,
              updatedUser,
              onRefresh: () {
                if (mounted) {
                  context.read<PointsProvider>().refresh();
                }
              },
            );
          }

          // Notificar al padre que el usuario fue actualizado
          if (widget.onUserUpdated != null) {
            widget.onUserUpdated!(updatedUser);
          }
        } else {}
      } else {}
    } catch (e) {
      // Error al cargar datos del usuario, continuar con el usuario actual
    }
  }

  Future<void> _handleRefresh() async {
    await _loadUserData();
    await context.read<PointsProvider>().refresh();
  }

  // Métodos helper para validar tipo de usuario según ROLE_ID
  // ROLE_ID: 1 = MANAGER, 2 = VENDEDOR, 3 = INFLUENCIADOR
  bool get _isManager => _currentUser.roleId == 1;
  bool get _isVendedor => _currentUser.roleId == 2;
  bool get _isInfluenciador => _currentUser.roleId == 3;

  // Métodos para validar si se debe mostrar una sección según el tipo de usuario
  bool _shouldShowSectionForManager() => _isManager;
  bool _shouldShowSectionForVendedor() => _isVendedor;
  bool _shouldShowSectionForInfluenciador() => _isInfluenciador;

  // Método para validar múltiples roles
  bool _shouldShowSectionForRoles(List<int> allowedRoles) {
    if (_currentUser.roleId == null) return false;
    return allowedRoles.contains(_currentUser.roleId);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '¡Hola ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'ShellTHAI',
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_currentUser.name}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'ShellHeavy',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tarjeta de puntos completa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Primera fila: Puntos disponibles
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Puntos disponibles',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'ShellHeavy',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Consumer<PointsProvider>(
                                      builder: (context, pointsProvider, child) {
                                        if (pointsProvider.isLoading) {
                                          return const SizedBox(
                                            width: 40,
                                            height: 20,
                                            child: Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Text(
                                          pointsProvider.availablePoints
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'ShellHeavy',
                                            height: 1.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Segunda fila: Puntos generados y Puntos extra (dos columnas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Consumer<PointsProvider>(
                      builder: (context, pointsProvider, child) {
                        final puntosGenerados = pointsProvider.isLoading
                            ? 0
                            : pointsProvider.availableWithoutExtras;
                        final puntosExtra = pointsProvider.isLoading
                            ? 0
                            : pointsProvider.extraPoints;

                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Puntos generados',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'ShellBook',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      puntosGenerados.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'ShellTHAI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Puntos extra',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'ShellBook',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      puntosExtra.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'ShellTHAI',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Ejemplo de validación de sección según ROLE_ID
            // Usar _isManager, _isVendedor, _isInfluenciador o _shouldShowSectionForRoles([1, 2])
            // para mostrar/ocultar secciones según el tipo de usuario
            // ROLE_ID: 1 = MANAGER, 2 = VENDEDOR, 3 = INFLUENCIADOR

            // Título de premios
            const Text(
              'Estos premios están listos para canjear',
              style: TextStyle(fontSize: 15, fontFamily: 'ShellTHAI'),
            ),

            const SizedBox(height: 16),

            // Scroll horizontal de premios
            _HomeProductsList(user: _currentUser),
            const SizedBox(height: 10),

            // Carrusel de banners promocionales
            _buildBannerCarousel(),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getBannerItems() {
    final productsProvider = context.read<ProductsProvider>();
    final carouselProducts = productsProvider.products
        .where((p) => p.category.toUpperCase() == 'CARRUSEL')
        .toList();

    if (carouselProducts.isNotEmpty) {
      final List<Map<String, dynamic>> items = [];
      for (var product in carouselProducts) {
        for (var route in product.routes) {
          if (route.url != null && route.url!.isNotEmpty) {
            items.add({'image': route.url, 'action': () {}});
          }
        }
      }

      if (items.isNotEmpty) return items;
    }

    return [];
  }

  Widget _buildBannerCarousel() {
    final bannerItems = _getBannerItems();

    if (bannerItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Carrusel de banners (proporción 1536x1024 para imagen completa sin recorte)
        AspectRatio(
          aspectRatio: 1536 / 1000,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: bannerItems.length,
            itemBuilder: (context, index) {
              final item = bannerItems[index];
              final action = item['action'] as VoidCallback?;
              final imagePath = item['image'] as String;
              final isNetworkImage = imagePath.startsWith('http');

              return GestureDetector(
                onTap: action,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isNetworkImage
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            );
                          },
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicadores de carrusel dinámicos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerItems.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? AppColors.primary
                    : Colors.grey.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
