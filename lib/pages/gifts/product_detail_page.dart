import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../api/user_api.dart';
import '../../api/points_api.dart';
import '../../api/gifts_api.dart';
import '../../contexts/points_provider.dart';
import '../../utils/failed_image_cache.dart';

class ProductDetailPage extends StatefulWidget {
  final UserModel user;
  final String imagePath; // Mantener para compatibilidad
  final List<String>? imagePaths; // Lista de todas las imágenes
  final String title;
  final int points;
  final String description;
  final String category;
  final int availablePoints;
  final String? productId;

  /// Especificación (talla) del producto. Si es null, no se muestra selector.
  final SpecificationModel? specification;

  const ProductDetailPage({
    super.key,
    required this.user,
    this.imagePath = '',
    this.imagePaths,
    required this.title,
    required this.points,
    required this.description,
    required this.category,
    this.availablePoints = 0,
    this.productId,
    this.specification,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _showSuccessScreen = false;
  Map<String, dynamic>? _selectedAddress;
  bool _isRedeeming = false;
  int _quantity = 1;

  /// Talla seleccionada por el usuario (cuando el producto tiene especificación).
  String? _selectedSize;

  /// Especificación (talla) vigente. Se inicializa con la que llega desde la
  /// lista (posiblemente cacheada) y se refresca con datos frescos del backend.
  SpecificationModel? _specification;

  /// True si el producto requiere que se elija una talla.
  bool get _requiresSize =>
      _specification != null && _specification!.values.isNotEmpty;

  /// Consulta el producto por ID para obtener su especificación actualizada,
  /// evitando depender del caché de la lista de productos.
  Future<void> _refreshSpecification() async {
    final productId = widget.productId;
    if (productId == null || productId.isEmpty) return;

    try {
      final response = await GiftsApi.getProductById(productId);
      if (!mounted || !response.success || response.data == null) return;

      final product = ProductModel.fromJson(response.data!);
      final fresh = product.specification;

      // Solo actualizar si cambió, para no reconstruir innecesariamente.
      final changed =
          (fresh?.id ?? '') != (_specification?.id ?? '') ||
          (fresh?.values.length ?? 0) != (_specification?.values.length ?? 0);
      if (changed) {
        setState(() {
          _specification = fresh;
          // Si la talla seleccionada ya no es válida, limpiarla.
          if (_selectedSize != null &&
              !(fresh?.values.contains(_selectedSize) ?? false)) {
            _selectedSize = null;
          }
        });
      }
    } catch (_) {
      // Silencioso: si falla, se conserva la especificación inicial.
    }
  }

  /// Selector de talla para productos con especificación (ej. prendas de vestir).
  Widget _buildSizeSelector() {
    final spec = _specification!;
    final label = spec.name.isNotEmpty ? spec.name : 'Talla';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'ShellBook',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSize,
              isExpanded: true,
              hint: const Text(
                'Seleccionar talla',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'ShellBook',
                  color: AppColors.textSecondary,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: spec.values
                  .map(
                    (size) => DropdownMenuItem<String>(
                      value: size,
                      child: Text(
                        size,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'ShellBook',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSize = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _specification = widget.specification;
    // Refrescar la especificación con datos frescos del backend (evita el caché
    // de la lista, que puede no traer la talla si se asignó recientemente).
    _refreshSpecification();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getProductImages() {
    // Usar imagePaths si está disponible, sino usar imagePath como fallback
    final List<String> images = [];

    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      // Usar todas las imágenes de la lista
      images.addAll(widget.imagePaths!);
    } else if (widget.imagePath.isNotEmpty) {
      // Fallback a imagePath si imagePaths no está disponible
      images.add(widget.imagePath);
    }

    // Si no hay imágenes, retornar lista vacía (se mostrará placeholder)
    return images;
  }

  @override
  Widget build(BuildContext context) {
    // Si debe mostrar la pantalla de éxito
    if (_showSuccessScreen) {
      return _buildSuccessScreen();
    }

    final productImages = _getProductImages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 56,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/images/brand/1-LOGO-CLUB-SHELL-MAXX2.jpeg',
            height: 18,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Icono de navegación y título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'ShellHeavy',
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Imagen del producto
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 5,
                  bottom: 5,
                ),
                child: Column(
                  children: [
                    // Imagen o carrusel de imágenes
                    Expanded(
                      child: productImages.isEmpty
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : productImages.length == 1
                          ? _buildSingleImage(productImages[0])
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: productImages.length,
                              itemBuilder: (context, index) {
                                return _buildImageWidget(productImages[index]);
                              },
                            ),
                    ),
                    // Indicadores de carrusel (solo si hay más de una imagen)
                    if (productImages.length > 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          productImages.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppColors.primary
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Información del producto
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    // Parte scrollable: descripción y términos
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 5,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              'Detalles:',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellTHAI',
                                height: 1.5,
                              ),
                            ),
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellTHAI',
                                height: 1.5,
                              ),
                            ),
                            // Términos y condiciones - Solo mostrar si la categoría es "EQUIPA TU PDV"
                            if (widget.category.toUpperCase().trim() ==
                                'EQUIPA TU PDV') ...[
                              const SizedBox(height: 16),
                              Text(
                                'Los premios pueden variar en color y diseño según la disponibilidad del proveedor.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'ShellBookItalic',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Parte fija: puntos y botón (siempre visibles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Puntos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icono y puntos a la izquierda
                              Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: const Color.fromRGBO(221, 29, 33, 1),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _quantity > 1
                                        ? '${widget.points} × $_quantity = ${widget.points * _quantity} pts'
                                        : widget.points.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'ShellHeavy',
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              // Mensaje de puntos faltantes a la derecha
                              if ((widget.points * _quantity) > widget.availablePoints)
                                Text(
                                  'Te faltan ${(widget.points * _quantity) - widget.availablePoints} puntos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'ShellBook',
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          // Selector de talla (solo si el producto tiene especificación)
                          if (_requiresSize) ...[
                            const SizedBox(height: 16),
                            _buildSizeSelector(),
                          ],
                          const SizedBox(height: 16),
                          // Contador de cantidad y botón canjear
                          Row(
                            children: [
                              // Contador de cantidad
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón restar
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: _quantity > 1
                                          ? () {
                                              setState(() {
                                                _quantity--;
                                              });
                                            }
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      color: _quantity > 1
                                          ? AppColors.textPrimary
                                          : Colors.grey[400],
                                    ),
                                    // Cantidad
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        _quantity.toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'ShellHeavy',
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    // Botón sumar
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: (widget.points * (_quantity + 1)) <= widget.availablePoints
                                          ? () {
                                              setState(() {
                                                _quantity++;
                                              });
                                            }
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      color: (widget.points * (_quantity + 1)) <= widget.availablePoints
                                          ? AppColors.textPrimary
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón canjear
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        (_isRedeeming ||
                                            (widget.points * _quantity) > widget.availablePoints ||
                                            (_requiresSize && _selectedSize == null))
                                        ? null
                                        : () {
                                            _navigateToSuccessPage(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.black,
                                      disabledBackgroundColor: AppColors.secondary
                                          .withValues(alpha: 0.6),
                                      disabledForegroundColor: Colors.black54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isRedeeming
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.black,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Canjear${_quantity > 1 ? ' ($_quantity)' : ''}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'ShellHeavy',
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imagePath.isNotEmpty
            ? (imagePath.startsWith('http')
                  ? (FailedImageCache.isFailed(imagePath)
                      ? Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        )
                      : Image.network(
                          imagePath,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            FailedImageCache.addFailed(imagePath);
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ))
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ))
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildSingleImage(String imagePath) {
    return _buildImageWidget(imagePath);
  }

  void _navigateToSuccessPage(BuildContext context) async {
    setState(() {
      _isRedeeming = true;
    });

    try {
      final categoryUpper = widget.category.toUpperCase().trim();
      
      // Si el usuario es vendedor, no necesita dirección
      if (widget.user.isVendedorByRole) {
        // Vendedores no tienen direcciones, proceder directamente con el canje
        _selectedAddress = null;
        _simulateApiProcess(context);
        return;
      }

      // Si la categoría es "EXPERIENCIAS", no necesita dirección (canje directo)
      if (categoryUpper == 'EXPERIENCIAS' || categoryUpper.contains('EXPERIENCIA')) {
        _selectedAddress = null;
        _simulateApiProcess(context);
        return;
      }

      // Si la categoría NO es "MODO RELAX", mostrar diálogo de selección de dirección
      if (categoryUpper != 'MODO RELAX') {
        final selectedAddress = await _showAddressSelectionDialog(context);
        if (selectedAddress == null) {
          // El usuario canceló la selección
          setState(() {
            _isRedeeming = false;
          });
          return;
        }
        _selectedAddress = selectedAddress;
      } else {
        // Para MODO RELAX, obtener la primera dirección disponible sin mostrar diálogo
        try {
          final apiResponse = await UserApi.getUserAddress(widget.user.id);
          if (apiResponse.success && apiResponse.data != null) {
            List<Map<String, dynamic>> addresses = [];
            if (apiResponse.data is List) {
              final dataList = apiResponse.data as List;
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  addresses.add(item);
                }
              }
            } else if (apiResponse.data is Map<String, dynamic>) {
              final data = apiResponse.data as Map<String, dynamic>;
              if (data.containsKey('ID_ADDRESS') ||
                  data.containsKey('ID_USER')) {
                addresses.add(data);
              }
            }
            if (addresses.isNotEmpty) {
              _selectedAddress = addresses[0];
            }
          }
        } catch (e) {
          // Error al obtener dirección para MODO RELAX
        }
      }

      // Simular proceso de API
      _simulateApiProcess(context);
    } catch (e) {
      setState(() {
        _isRedeeming = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _showAddressSelectionDialog(
    BuildContext context,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _AddressSelectionDialog(user: widget.user),
    );
  }

  Future<void> _simulateApiProcess(BuildContext context) async {
    try {
      // Validar que tenemos productId
      if (widget.productId == null || widget.productId!.isEmpty) {
        if (mounted) {
          setState(() {
            _isRedeeming = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo identificar el producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Para vendedores y experiencias, no se envía addressId (será null)
      // Para manager e influenciador con otras categorías, addressId es requerido
      int? addressId;
      final categoryUpper = widget.category.toUpperCase().trim();
      final isExperiencias = categoryUpper == 'EXPERIENCIAS' || categoryUpper.contains('EXPERIENCIA');

      if (widget.user.isVendedorByRole || isExperiencias) {
        // Vendedores y experiencias no envían addressId
        addressId = null;
      } else {
        // Manager e influenciador deben tener una dirección seleccionada
        if (_selectedAddress == null) {
          if (mounted) {
            setState(() {
              _isRedeeming = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Debe seleccionar una dirección de envío'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Extraer addressId de la dirección seleccionada
        if (_selectedAddress!.containsKey('ID_ADDRESS')) {
          final id = _selectedAddress!['ID_ADDRESS'];
          if (id is int) {
            addressId = id;
          } else if (id is String) {
            addressId = int.tryParse(id);
          }
        } else if (_selectedAddress!.containsKey('id')) {
          final id = _selectedAddress!['id'];
          if (id is int) {
            addressId = id;
          } else if (id is String) {
            addressId = int.tryParse(id);
          }
        }

        if (addressId == null) {
          if (mounted) {
            setState(() {
              _isRedeeming = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo identificar la dirección'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Llamar al endpoint real
      final apiResponse = await PointsApi.redeemProduct(
        productId: widget.productId!,
        addressId: addressId,
        comments: '',
        quantity: _quantity,
        specificationValue: _selectedSize,
      );

      if (mounted) {
        if (apiResponse.success) {
          // Actualizar puntos en el provider
          try {
            final pointsProvider = context.read<PointsProvider>();
            await pointsProvider.refresh();
          } catch (e) {
            // Error al actualizar puntos en provider
          }

          setState(() {
            _isRedeeming = false;
            _showSuccessScreen = true;
          });
        } else {
          setState(() {
            _isRedeeming = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                apiResponse.message.isNotEmpty
                    ? apiResponse.message
                    : 'Error al canjear el producto',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error al canjear producto
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al procesar el canje. Por favor intenta de nuevo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // Elementos decorativos de fondo
            ..._buildDecorativeElements(),

            // Contenido principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mensaje de éxito
                  const Text(
                    '¡Canje realizado con éxito!',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'ShellHeavy',
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Botón inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Canjear más premios',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'ShellHeavy',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeElements() {
    return [
      // Círculos pequeños muy cerca del texto
      _buildAnimatedElement(
        top: 350,
        left: 60,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 420,
        left: 160,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 310,
        left: 220,
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 365,
        right: 85,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondary, width: 2),
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 455,
        right: 65,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        ),
      ),

      // Iconos decorativos muy cerca del texto
      _buildAnimatedElement(
        top: 330,
        left: 110,
        child: Transform.rotate(
          angle: 0.45,
          child: Image.asset(
            'assets/images/icons/gift.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            color: AppColors.secondary,
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 420,
        left: 75,
        child: Transform.rotate(
          angle: -0.20,
          child: Image.asset(
            'assets/images/icons/giftr.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 305,
        right: 67,
        child: Transform.rotate(
          angle: 0.20,
          child: Image.asset(
            'assets/images/icons/energyr.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
      ),

      _buildAnimatedElement(
        top: 430,
        right: 130,
        child: Transform.rotate(
          angle: 0.35,
          child: Icon(
            Icons.water_drop_outlined,
            size: 25,
            color: AppColors.primary,
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 330,
        left: 165,
        child: Transform.rotate(
          angle: -0.35,
          child: Icon(
            Icons.water_drop_outlined,
            size: 35,
            color: AppColors.secondary,
          ),
        ),
      ),
      _buildAnimatedElement(
        top: 415,
        right: 90,
        child: Transform.rotate(
          angle: 0.2,
          child: Icon(
            Icons.emoji_events,
            size: 25,
            color: AppColors.secondary.withValues(alpha: 0.7),
          ),
        ),
      ),

      _buildAnimatedElement(
        top: 390,
        left: 40,
        child: Transform.rotate(
          angle: 0.2,
          child: Icon(Icons.auto_awesome, size: 30, color: AppColors.secondary),
        ),
      ),
      _buildAnimatedElement(
        top: 410,
        right: 50,
        child: Transform.rotate(
          angle: 0.2,
          child: Icon(Icons.auto_awesome, size: 10, color: AppColors.secondary),
        ),
      ),
    ];
  }

  Widget _buildAnimatedElement({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        // Obtener el tamaño de la pantalla
        final screenSize = MediaQuery.of(context).size;
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;

        // Calcular posición actual interpolando desde el centro
        double? currentTop;
        double? currentBottom;
        double? currentLeft;
        double? currentRight;

        // Calcular posición vertical
        if (top != null) {
          // Animar desde el centro hacia la posición top final
          currentTop = centerY + (top - centerY) * value;
        } else if (bottom != null) {
          // Animar desde el centro hacia la posición bottom final
          final finalBottomFromTop = screenSize.height - bottom;
          final currentBottomFromTop =
              centerY + (finalBottomFromTop - centerY) * value;
          currentBottom = screenSize.height - currentBottomFromTop;
        } else {
          // Si no hay top ni bottom, mantener en el centro vertical
          currentTop = centerY;
        }

        // Calcular posición horizontal
        if (left != null) {
          // Animar desde el centro hacia la posición left final
          currentLeft = centerX + (left - centerX) * value;
        } else if (right != null) {
          // Animar desde el centro hacia la posición right final
          final finalRightFromLeft = screenSize.width - right;
          final currentRightFromLeft =
              centerX + (finalRightFromLeft - centerX) * value;
          currentRight = screenSize.width - currentRightFromLeft;
        } else {
          // Si no hay left ni right, mantener en el centro horizontal
          currentLeft = centerX;
        }

        // Escala: comienza en 0.0 (muy pequeño) y termina en 1.0 (tamaño normal)
        final scaleValue = value;

        return Positioned(
          top: currentTop,
          bottom: currentBottom,
          left: currentLeft,
          right: currentRight,
          child: Transform.scale(scale: scaleValue, child: child),
        );
      },
      child: child,
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['ADDRESS'] != null || address['address'] != null) {
      parts.add((address['ADDRESS'] ?? address['address']).toString());
    }

    if (address['CITY'] != null || address['city'] != null) {
      parts.add((address['CITY'] ?? address['city']).toString());
    }

    if (address['PROVINCE'] != null || address['province'] != null) {
      parts.add((address['PROVINCE'] ?? address['province']).toString());
    }

    return parts.join(', ');
  }
}

// Diálogo de selección de dirección
class _AddressSelectionDialog extends StatefulWidget {
  final UserModel user;

  const _AddressSelectionDialog({required this.user});

  @override
  State<_AddressSelectionDialog> createState() =>
      _AddressSelectionDialogState();
}

class _AddressSelectionDialogState extends State<_AddressSelectionDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await UserApi.getUserAddress(widget.user.id);

      if (apiResponse.success && mounted) {
        List<Map<String, dynamic>> addresses = [];

        // Intentar obtener desde apiResponse.data (puede ser array o objeto)
        if (apiResponse.data != null) {
          if (apiResponse.data is List) {
            final dataList = apiResponse.data as List;
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                addresses.add(item);
              }
            }
          } else if (apiResponse.data is Map<String, dynamic>) {
            final data = apiResponse.data as Map<String, dynamic>;
            if (data.containsKey('ID_ADDRESS') || data.containsKey('ID_USER')) {
              addresses.add(data);
            }
          }
        }

        // Si no está en data, intentar desde rawData
        if (addresses.isEmpty && apiResponse.rawData != null) {
          Map<String, dynamic>? actualData = apiResponse.rawData;
          if (apiResponse.rawData!.containsKey('body')) {
            final body = apiResponse.rawData!['body'];
            if (body is Map<String, dynamic>) {
              actualData = body;
            } else if (body is String) {
              try {
                actualData = jsonDecode(body) as Map<String, dynamic>?;
              } catch (e) {
                // Error al parsear body
              }
            }
          }

          if (actualData != null && actualData.containsKey('data')) {
            final data = actualData['data'];
            if (data is List) {
              for (var item in data) {
                if (item is Map<String, dynamic>) {
                  addresses.add(item);
                }
              }
            } else if (data is Map<String, dynamic>) {
              if (data.containsKey('ID_ADDRESS') ||
                  data.containsKey('ID_USER')) {
                addresses.add(data);
              }
            }
          }
        }

        setState(() {
          _addresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses[0];
          }
        });
      }
    } catch (e) {
      // Error al cargar direcciones
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['ADDRESS'] != null || address['address'] != null) {
      parts.add((address['ADDRESS'] ?? address['address']).toString());
    }

    if (address['CITY'] != null || address['city'] != null) {
      parts.add((address['CITY'] ?? address['city']).toString());
    }

    if (address['PROVINCE'] != null || address['province'] != null) {
      parts.add((address['PROVINCE'] ?? address['province']).toString());
    }

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: _addresses.length == 1 ? 0.4 : 0.7,
        minChildSize: _addresses.length == 1 ? 0.3 : 0.5,
        maxChildSize: _addresses.length == 1 ? 0.5 : 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _addresses.length == 1
                          ? 'Confirmar dirección de envío'
                          : 'Seleccionar dirección de envío',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'ShellHeavy',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Lista de direcciones
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _addresses.isEmpty
                    ? const Center(
                        child: Text('No hay direcciones disponibles'),
                      )
                    : _addresses.length == 1
                    ? // Si hay solo una dirección, mostrar sin opciones de selección
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatAddress(_addresses[0]),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : // Si hay más de una, mostrar lista con opciones de selección
                      ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final address = _addresses[index];
                          final isSelected = _selectedAddress == address;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondary.withValues(alpha: 0.2)
                                    : Colors.grey[100],
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppColors.secondary
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _formatAddress(address),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Botón confirmar
              if (!_isLoading && _addresses.isNotEmpty)
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          ((_addresses.length == 1 ||
                                  _selectedAddress != null) &&
                              !_isConfirming)
                          ? () {
                              setState(() {
                                _isConfirming = true;
                              });
                              // Simular un pequeño delay para mostrar el loader
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  if (mounted) {
                                    // Si hay solo una dirección, usar esa; si no, usar la seleccionada
                                    final addressToReturn =
                                        _addresses.length == 1
                                        ? _addresses[0]
                                        : _selectedAddress;
                                    Navigator.pop(context, addressToReturn);
                                  }
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.secondary.withValues(
                          alpha: 0.6,
                        ),
                        disabledForegroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirmar',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellHeavy',
                                color: AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
