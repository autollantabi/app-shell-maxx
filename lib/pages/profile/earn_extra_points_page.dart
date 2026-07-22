import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dynamic_detail_page.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/user_model.dart';
import '../../models/extra_point_dynamic.dart';
import '../../layouts/main_layout.dart';
import '../../api.dart';

class EarnExtraPointsPage extends StatefulWidget {
  final UserModel user;

  const EarnExtraPointsPage({super.key, required this.user});

  @override
  State<EarnExtraPointsPage> createState() => _EarnExtraPointsPageState();
}

class _EarnExtraPointsPageState extends State<EarnExtraPointsPage> {
  bool _isLoading = true;
  List<ExtraPointDynamic> _dynamics = [];

  @override
  void initState() {
    super.initState();
    _fetchDynamics();
  }

  Future<void> _fetchDynamics() async {
    try {
      final response = await ApiConfig.getResponse(
        '/influencer-dynamics/app/extra-points',
      );

      if (response.success && response.data is List) {
        final list = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(ExtraPointDynamic.fromJson)
            .toList();
        if (mounted) {
          setState(() {
            _dynamics = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
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

  void _onDynamicTap(ExtraPointDynamic item) {
    // Pantalla de detalle genérica: cualquier item disponible navega aquí.
    // Los items no disponibles ya están bloqueados/no seleccionables en la lista.
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DynamicDetailPage(user: widget.user, dynamic: item),
      ),
    );
  }

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
      body: RefreshIndicator(
        onRefresh: _fetchDynamics,
        color: AppColors.primary,
        child: SingleChildScrollView(
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
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_dynamics.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Text(
                      'Por ahora no hay dinámicas disponibles.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'ShellBook',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: _dynamics
                        .map(
                          (item) => _buildExtraOption(
                            iconUrl: item.iconUrl,
                            fallbackAsset: item.iconAssetPath,
                            title: item.title,
                            subtitle: item.subtitle,
                            badgeText: item.badgeText,
                            badgeBgColor: item.badgeColor,
                            isLocked: !item.available,
                            onTap: () => _onDynamicTap(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Perfil
        user: widget.user,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (context) =>
                    MainLayout(user: widget.user, initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionIcon(String? iconUrl, String fallbackAsset) {
    final fallback = Image.asset(fallbackAsset, fit: BoxFit.contain);
    if (iconUrl == null || iconUrl.isEmpty) {
      return fallback;
    }
    return Image.network(
      iconUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildExtraOption({
    required String? iconUrl,
    required String fallbackAsset,
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
                        child: _buildOptionIcon(iconUrl, fallbackAsset),
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
