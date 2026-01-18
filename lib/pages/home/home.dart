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

        // Obtener productos que el usuario puede reclamar
        final pointsProvider = context.watch<PointsProvider>();
        final affordableProducts = productsProvider.products
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
          final otherProducts = productsProvider.products
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
  final Function(UserModel)? onUserUpdated;

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


      if (!apiResponse.success) {
      }
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

          // Notificar al padre que el usuario fue actualizado
          if (widget.onUserUpdated != null) {
            widget.onUserUpdated!(updatedUser);
          }
        } else {
        }
      } else {
      }
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
                    fontFamily: 'ShellBold',
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
                                  fontFamily: 'ShellBold',
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
                                            fontFamily: 'ShellBold',
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
                  // Segunda fila: Puntos acumulados
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Consumer<PointsProvider>(
                      builder: (context, pointsProvider, child) {
                        final totalPoints = pointsProvider.isLoading
                            ? 0
                            : pointsProvider.totalPoints;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Puntos acumulados:',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'ShellTHAI',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                totalPoints.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'ShellTHAI',
                                ),
                              ),
                            ),
                          ],
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
            const SizedBox(height: 32),

            // Carrusel de banners promocionales
            _buildBannerCarousel(),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getBannerItems() {
    return [
      {
        'image': 'assets/images/app/ferrari-banner-1.jpg',
        'title': 'Nueva colección',
        'subtitle': 'Autitos Ferrari',
        'description': 'para llevar tu colección a lo más alto del podio.',
        'badge': 'Ferrari Innovation Partner',
        'action': () => _navigateToFerrariPage(),
      },
      {
        'image': 'assets/images/app/shell-promo-1.jpg',
        'title': 'Promoción Especial',
        'subtitle': 'Shell V-Power',
        'description': 'Combustible premium para el máximo rendimiento.',
        'badge': 'Shell V-Power',
        'action': () => _navigateToShellPromoPage(),
      },
      {
        'image': 'assets/images/app/racing-banner-1.jpg',
        'title': 'Carreras Shell',
        'subtitle': 'Temporada 2024',
        'description': 'Sé parte de la experiencia Shell Racing.',
        'badge': 'Racing 2024',
        'action': () => _navigateToRacingPage(),
      },
      {
        'image': 'assets/images/app/loyalty-banner-1.jpg',
        'title': 'Programa Lealtad',
        'subtitle': 'Club Shell Premium',
        'description': 'Beneficios exclusivos para miembros premium.',
        'badge': 'Premium Member',
        'action': () => _navigateToLoyaltyPage(),
      },
    ];
  }

  void _navigateToFerrariPage() {
    // Aquí puedes navegar a una página específica de Ferrari
  }

  void _navigateToShellPromoPage() {
    // Aquí puedes navegar a una página de promociones Shell
  }

  void _navigateToRacingPage() {
    // Aquí puedes navegar a una página de carreras
  }

  void _navigateToLoyaltyPage() {
    // Aquí puedes navegar a una página de lealtad
  }

  Widget _buildBannerCarousel() {
    final bannerItems = _getBannerItems();

    return Column(
      children: [
        // Carrusel de banners
        SizedBox(
          height: 160,
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
              return GestureDetector(
                onTap: item['action'],
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(item['image']),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Si la imagen no existe, usar color de fondo
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Logo Shell
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Image.asset(
                            'assets/images/brand/logo-shell.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                        // Badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['badge'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        // Texto principal
                        Positioned(
                          left: 16,
                          top: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Texto descriptivo
                        Positioned(
                          left: 16,
                          bottom: 20,
                          child: Text(
                            item['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
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
