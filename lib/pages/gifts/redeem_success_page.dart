import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';

class RedeemSuccessPage extends StatelessWidget {
  final UserModel user;
  final String productTitle;
  final int points;

  const RedeemSuccessPage({
    super.key,
    required this.user,
    required this.productTitle,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header con texto del catálogo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Text(
              'catalogo_giftcards',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // Contenido principal
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Botón inferior
                  Positioned(
                    bottom: 30,
                    left: 30,
                    right: 30,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeElements() {
    return [
      // Círculos pequeños dispersos
      Positioned(
        top: 60,
        left: 40,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 80,
        right: 60,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 120,
        left: 60,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 140,
        right: 40,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 120,
        left: 50,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        right: 50,
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),

      // Iconos decorativos
      Positioned(
        top: 80,
        left: 30,
        child: Transform.rotate(
          angle: -0.3,
          child: Image.asset(
            'assets/images/icons/gift.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            color: AppColors.secondary.withValues(alpha: 0.7),
          ),
        ),
      ),
      Positioned(
        top: 70,
        left: 0,
        right: 0,
        child: Center(
          child: Icon(
            Icons.water_drop,
            size: 20,
            color: AppColors.secondary.withValues(alpha: 0.7),
          ),
        ),
      ),
      Positioned(
        top: 80,
        right: 30,
        child: Transform.rotate(
          angle: 0.2,
          child: Icon(
            Icons.flash_on,
            size: 22,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
      Positioned(
        bottom: 150,
        left: 30,
        child: Transform.rotate(
          angle: 0.3,
          child: Image.asset(
            'assets/images/icons/giftr.png',
            width: 26,
            height: 26,
            fit: BoxFit.contain,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
      Positioned(
        bottom: 130,
        left: 0,
        right: 0,
        child: Center(
          child: Icon(
            Icons.water_drop,
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
      Positioned(
        bottom: 150,
        right: 30,
        child: Transform.rotate(
          angle: -0.2,
          child: Icon(
            Icons.emoji_events,
            size: 24,
            color: AppColors.secondary.withValues(alpha: 0.7),
          ),
        ),
      ),

      // Estrellas pequeñas
      Positioned(
        top: 100,
        left: 80,
        child: Icon(
          Icons.star,
          size: 12,
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        top: 130,
        right: 80,
        child: Icon(
          Icons.star,
          size: 10,
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        bottom: 180,
        left: 80,
        child: Icon(
          Icons.star,
          size: 14,
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        bottom: 200,
        right: 80,
        child: Icon(
          Icons.star,
          size: 11,
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
    ];
  }
}
