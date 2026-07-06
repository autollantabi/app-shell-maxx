import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../api.dart';
import '../theme/app_colors.dart';
import '../contexts/points_provider.dart';
import '../pages/gifts/product_detail_page.dart';
import '../utils/failed_image_cache.dart';

/// Widget reutilizable para mostrar una card de producto
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final UserModel user;
  final double? width; // Ancho opcional (para home que necesita 2 cards)

  const ProductCard({
    super.key,
    required this.product,
    required this.user,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener todas las URLs de ROUTES
    final imageUrls = <String>[];
    for (var route in product.routes) {
      if (route.url != null && route.url!.isNotEmpty) {
        imageUrls.add(route.url!);
      }
    }

    // Si no hay URLs en routes, usar imagePath como fallback
    final fallbackImageUrl = product.imagePath != null
        ? '${ApiConfig.baseUrl.replaceAll('/api', '')}/${product.imagePath!.replaceAll('\\', '/')}'
        : null;

    // Usar la primera URL disponible para la card
    final primaryImageUrl = imageUrls.isNotEmpty
        ? imageUrls[0]
        : fallbackImageUrl;

    // Preparar todas las imágenes para el detalle
    final allImageUrls = <String>[];
    if (imageUrls.isNotEmpty) {
      allImageUrls.addAll(imageUrls);
    } else if (fallbackImageUrl != null) {
      allImageUrls.add(fallbackImageUrl);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              user: user,
              imagePath: primaryImageUrl ?? product.localImagePath ?? '',
              imagePaths: allImageUrls.isNotEmpty ? allImageUrls : null,
              title: product.name,
              points: product.points,
              description: product.description,
              category: product.category,
              availablePoints: context.watch<PointsProvider>().availablePoints,
              productId: product.id,
            ),
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Imagen del producto: área flexible, imagen rellena el espacio (cover)
            Expanded(
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: Colors.transparent,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Center(
                        child:
                            primaryImageUrl != null &&
                                primaryImageUrl.isNotEmpty
                            ? (FailedImageCache.isFailed(primaryImageUrl)
                                  ? Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Image.network(
                                      primaryImageUrl,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            FailedImageCache.addFailed(
                                              primaryImageUrl,
                                            );
                                            final localImage =
                                                product.localImagePath;
                                            if (localImage != null) {
                                              return Image.asset(
                                                localImage,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.image,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                              );
                                            }
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            final progress =
                                                loadingProgress
                                                    .cumulativeBytesLoaded /
                                                (loadingProgress
                                                        .expectedTotalBytes ??
                                                    1);
                                            if (progress >= 1.0) return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                    ))
                            : product.localImagePath != null
                            ? Image.asset(
                                product.localImagePath!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (product.quantity != null && product.quantity! > 1)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Material(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'x${product.quantity}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'ShellHeavy',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Puntos y botón siempre abajo (misma altura en todas las cards)
            Padding(
              padding: const EdgeInsets.only(
                right: 4,
                left: 4,
                top: 8,
                bottom: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Puntos centrados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppColors.primary,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.points.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'ShellHeavy',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Botón canjear
                  Consumer<PointsProvider>(
                    builder: (context, pointsProvider, child) {
                      final hasEnoughPoints =
                          product.points <= pointsProvider.availablePoints;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Opacity(
                            opacity: hasEnoughPoints ? 1.0 : 0.5,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Canjear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'ShellHeavy',
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Espacio reservado para "Te faltan X puntos" (siempre ocupa sitio para no descuadrar)
                          const SizedBox(height: 2),
                          Opacity(
                            opacity: hasEnoughPoints ? 0.0 : 1.0,
                            child: Text(
                              'Te faltan ${product.points - pointsProvider.availablePoints} puntos',
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'ShellTHAI',
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
