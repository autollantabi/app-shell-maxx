import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../api/auth_api.dart';
import '../../contexts/products_provider.dart';
import '../../contexts/points_provider.dart';
import '../../widgets/product_card.dart';

/// Widget para cada tab de categoría que mantiene el estado vivo
class _CategoryTabWidget extends StatefulWidget {
  final String category;
  final Future<void> Function() onRefresh;
  final UserModel user;

  const _CategoryTabWidget({
    required this.category,
    required this.onRefresh,
    required this.user,
  });

  @override
  State<_CategoryTabWidget> createState() => _CategoryTabWidgetState();
}

class _CategoryTabWidgetState extends State<_CategoryTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, child) {
        if (productsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productsProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${productsProvider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => productsProvider.loadProducts(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Obtener productos de la categoría específica
        final categoryProducts = productsProvider.getProductsByCategory(
          widget.category,
        );

        if (categoryProducts.isEmpty) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: const Center(
                  child: Text('No hay productos disponibles en esta categoría'),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: categoryProducts.length,
            itemBuilder: (context, index) {
              final product = categoryProducts[index];
              return ProductCard(product: product, user: widget.user);
            },
          ),
        );
      },
    );
  }
}

class GiftsPage extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const GiftsPage({super.key, required this.user, this.onUserUpdated});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> with TickerProviderStateMixin {
  TabController? _tabController;
  late UserModel _currentUser;
  int _tabCount = 1; // Inicializar con 1 pestaña por defecto

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserData();

    // Inicializar TabController después de verificar si hay productos en caché
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productsProvider = context.read<ProductsProvider>();

      // Verificar si ya hay productos cargados (desde caché)
      final categories = productsProvider.categories;
      final initialTabCount = categories.isNotEmpty ? categories.length : 1;

      // Inicializar TabController con el número correcto de tabs
      _tabCount = initialTabCount;
      _tabController = TabController(length: _tabCount, vsync: this);

      // Solo cargar si no hay productos ya cargados (evitar recargas innecesarias)
      if (productsProvider.products.isEmpty) {
        productsProvider.loadProducts();
      }

      // Escuchar cambios en el provider para actualizar las pestañas
      productsProvider.addListener(_onProductsChanged);

      final pointsProvider = context.read<PointsProvider>();
      // Solo cargar puntos si no hay puntos cargados
      if (pointsProvider.availablePoints == 0 && !pointsProvider.isLoading) {
        pointsProvider.loadPoints();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onProductsChanged() {
    if (!mounted || _tabController == null) return;

    final productsProvider = context.read<ProductsProvider>();
    final categories = productsProvider.categories;
    final newTabCount = categories.isNotEmpty ? categories.length : 1;

    if (newTabCount != _tabCount && mounted) {
      _tabCount = newTabCount;
      final oldIndex = _tabController!.index;
      _tabController!.dispose();
      _tabController = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: oldIndex < _tabCount ? oldIndex : 0,
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final apiResponse = await AuthApi.getCurrentUser();

      if (apiResponse.success && mounted) {
        Map<String, dynamic>? userData;

        // Intentar obtener desde apiResponse.data primero
        if (apiResponse.data != null &&
            apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;
          if (data.containsKey('ID') || data.containsKey('id')) {
            userData = data;
          } else if (data.containsKey('usuarioData')) {
            userData = data['usuarioData'] as Map<String, dynamic>?;
          }
        }

        // Si no está en data, intentar desde rawData['data']
        if (userData == null && apiResponse.rawData != null) {
          if (apiResponse.rawData!.containsKey('data')) {
            final data = apiResponse.rawData!['data'];
            if (data is Map<String, dynamic>) {
              if (data.containsKey('ID') || data.containsKey('id')) {
                userData = data;
              } else if (data.containsKey('usuarioData')) {
                userData = data['usuarioData'] as Map<String, dynamic>?;
              }
            }
          } else if (apiResponse.rawData!.containsKey('usuarioData')) {
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
        }
      }
    } catch (e) {
      // Error al cargar datos del usuario, continuar con el usuario actual
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // Remover listener del provider
    try {
      context.read<ProductsProvider>().removeListener(_onProductsChanged);
    } catch (e) {
      // El provider puede no estar disponible al hacer dispose
    }
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<ProductsProvider>().refresh();
    await context.read<PointsProvider>().refresh();
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta de puntos completa
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
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
                            'Total de puntos',
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
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pointsProvider.availablePoints.toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'ShellHeavy',
                                            height: 1.0,
                                          ),
                                        ),
                                        
                                      ],
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
            ],
          ),
        ),

        // Tab Bar
        Consumer<ProductsProvider>(
          builder: (context, productsProvider, child) {
            final categories = productsProvider.categories;

            if (categories.isEmpty || _tabController == null) {
              return const SizedBox.shrink();
            }

            return Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController!,
                isScrollable: categories.length > 3,
                tabAlignment: categories.length > 3
                    ? TabAlignment.start
                    : TabAlignment.fill,
                padding: categories.length > 3
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : EdgeInsets.zero,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.secondary, width: 3),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.secondary,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                tabs: categories.map((category) {
                  // Normalizar el nombre de la categoría para mostrar
                  String displayName = category;
                  // Convertir "TEAM SHELL" a "Team Shell", "MODO RELAX" a "Modo Relax", etc.
                  displayName = displayName
                      .split(' ')
                      .map(
                        (word) => word.isEmpty
                            ? ''
                            : word[0].toUpperCase() +
                                  word.substring(1).toLowerCase(),
                      )
                      .join(' ');

                  return Tab(text: displayName);
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 15),

        // Tab Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<ProductsProvider>(
              builder: (context, productsProvider, child) {
                final categories = productsProvider.categories;

                if (categories.isEmpty || _tabController == null) {
                  return const Center(
                    child: Text('No hay productos disponibles'),
                  );
                }

                return TabBarView(
                  controller: _tabController!,
                  children: categories.map((category) {
                    return _buildCategoryTab(category);
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(String category) {
    return _CategoryTabWidget(
      category: category,
      onRefresh: _handleRefresh,
      user: _currentUser,
    );
  }
}
