import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'trivia_futbolera_page.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/user_model.dart';
import '../../layouts/main_layout.dart';

class EarnExtraPointsPage extends StatelessWidget {
  final UserModel user;

  const EarnExtraPointsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gana puntos extras',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior premium
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige como quieres sumar más puntos',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'ShellBook',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Opciones de ganar puntos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildExtraOption(
                    context: context,
                    imagePath: 'assets/images/icons/triviaFutbolera.png',
                    title: 'Trivias futboleras',
                    subtitle:
                        'Responde las trivias de cada semana y gana puntos.',
                    badgeText: 'Más de 2000 puntos',
                    badgeBgColor: Colors.green,
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => TriviaFutboleraPage(user: user),
                      ),
                    ),
                  ),
                  _buildExtraOption(
                    context: context,
                    imagePath: 'assets/images/icons/etiquetas.png',
                    title: 'Etiquetas',
                    subtitle:
                        'Suma puntos por cada etiqueta de nuestros productos.',
                    badgeText: 'Hasta 70 puntos',
                    badgeBgColor: Colors.red,
                    isLocked: true,
                    onTap: () {},
                  ),
                  _buildExtraOption(
                    context: context,
                    imagePath: 'assets/images/icons/retoShell.png',
                    title: 'Reto Shell en el taller',
                    subtitle:
                        'Crea, publica y etiqueta para ganar puntos extras.',
                    badgeText: 'Hasta 5 puntos',
                    badgeBgColor: Colors.brown,
                    isLocked: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Perfil
        user: user,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (context) =>
                    MainLayout(user: user, initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildExtraOption({
    required BuildContext context,
    required String imagePath,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBgColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: AppColors.shadowLight,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Ícono redondeado
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 16),
                      // Texto central
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge superior de puntos
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isLocked ? Colors.grey : badgeBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'ShellHeavy',
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShellHeavy',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'ShellBook',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isLocked)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  if (isLocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
