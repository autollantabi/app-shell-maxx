import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import 'como_participar_page.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/user_model.dart';
import '../../models/extra_point_dynamic.dart';
import '../../layouts/main_layout.dart';
import 'participaciones_page.dart';
import '../../api.dart';

/// Pantalla de detalle genérica para cualquier trivia/dinámica de "Gana puntos extras".
/// Todo el contenido (título, imagen, textos, CTA, instructivo) viene del back
/// mediante el objeto [ExtraPointDynamic]. El bloque de progreso "X de Y" solo se
/// muestra cuando la dinámica lo indica (showsProgress).
class DynamicDetailPage extends StatefulWidget {
  final UserModel user;
  final ExtraPointDynamic dynamic;

  const DynamicDetailPage({
    super.key,
    required this.user,
    required this.dynamic,
  });

  @override
  State<DynamicDetailPage> createState() => _DynamicDetailPageState();
}

class _DynamicDetailPageState extends State<DynamicDetailPage> {
  static const String _headerFallbackAsset =
      'assets/images/app/EncabezadoTriviaFutbolera.png';

  static const List<String> _meses = [
    '',
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  bool _isLoading = false;
  int _triviaPoints = 0;
  int _completedQuizzes = 0;
  int _totalQuizzes = 0;
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.dynamic.showsProgress) {
      _isLoading = true;
      _fetchProgress();
    }
  }

  Future<void> _fetchProgress() async {
    try {
      final response = await ApiConfig.getResponse(
        '/influencer-dynamics/app/my-trivia-progress',
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _completedQuizzes = data['TRIVIAS_COMPLETADAS'] is int
                ? data['TRIVIAS_COMPLETADAS']
                : int.tryParse(data['TRIVIAS_COMPLETADAS'].toString()) ?? 0;

            _totalQuizzes = data['TOTAL_TRIVIAS'] is int
                ? data['TOTAL_TRIVIAS']
                : int.tryParse(data['TOTAL_TRIVIAS'].toString()) ?? 0;

            final double rawPercentage = data['PORCENTAJE_COMPLETADO'] is num
                ? (data['PORCENTAJE_COMPLETADO'] as num).toDouble()
                : double.tryParse(data['PORCENTAJE_COMPLETADO'].toString()) ?? 0.0;

            _progressPercentage = rawPercentage / 100.0;

            _triviaPoints = data['PUNTOS_EXTRA_ACUMULADOS'] is int
                ? data['PUNTOS_EXTRA_ACUMULADOS']
                : int.tryParse(data['PUNTOS_EXTRA_ACUMULADOS'].toString()) ?? 0;

            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _seasonDateRange {
    final start = widget.dynamic.startDate;
    final end = widget.dynamic.endDate;
    if (start == null && end == null) {
      return 'Temporada vigente';
    }
    if (start != null && end != null) {
      return 'Del ${_formatDay(start)} al ${_formatDay(end)}';
    }
    if (start != null) {
      return 'Desde el ${_formatDay(start)}';
    }
    return 'Hasta el ${_formatDay(end!)}';
  }

  String _formatDay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} de ${_meses[date.month]} de ${date.year}';
  }

  Future<void> _openCta(BuildContext context) async {
    final url = widget.dynamic.ctaUrl;
    if (!widget.dynamic.available || url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta dinámica no está disponible en este momento'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir enlace: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildHeaderImage() {
    final url = widget.dynamic.headerImageUrl;
    final fallback = Image.asset(
      _headerFallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.green[800],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 64, color: Colors.white70),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (url == null || url.isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildCtaIcon() {
    switch (widget.dynamic.ctaIconKey?.toLowerCase()) {
      case 'instagram':
        return _InstagramIcon(
          color: widget.dynamic.available
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          size: 22,
        );
      case 'whatsapp':
        return const Icon(Icons.chat, size: 22);
      default:
        return const Icon(Icons.open_in_new, size: 22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final dynamic = widget.dynamic;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: dynamic.showsProgress ? _fetchProgress : () async {},
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado (imagen desde el back con fallback local)
              Container(
                width: double.infinity,
                height: 180,
                decoration: const BoxDecoration(color: Colors.white),
                child: _buildHeaderImage(),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dynamic.showsProgress) ...[
                      _buildPointsCard(context, user),
                      const SizedBox(height: 20),
                      _buildSeasonCard(),
                      const SizedBox(height: 24),
                    ],
                    if (dynamic.howToParticipate != null ||
                        (dynamic.detailDescription != null))
                      _buildHowToCard(context),
                    if (dynamic.ctaUrl != null && dynamic.ctaUrl!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildCtaButton(context),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        user: user,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (context) => MainLayout(user: user, initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.dynamic.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'ShellHeavy',
        ),
      ),
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildPointsCard(BuildContext context, UserModel user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => ParticipacionesPage(
                triviaPoints: _triviaPoints,
                user: user,
                instagramQuizUrl: widget.dynamic.ctaUrl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puntos acumulados',
                      style: TextStyle(
                        fontFamily: 'ShellBook',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_triviaPoints',
                      style: const TextStyle(
                        fontFamily: 'ShellHeavy',
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_month, color: Colors.green[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temporada actual',
                      style: TextStyle(
                        fontFamily: 'ShellHeavy',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _seasonDateRange,
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu participación: $_completedQuizzes de $_totalQuizzes',
                style: const TextStyle(
                  fontFamily: 'ShellHeavy',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(_progressPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'ShellHeavy',
                  fontSize: 13,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progressPercentage,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToCard(BuildContext context) {
    final howTo = widget.dynamic.howToParticipate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.dynamic.detailDescription ?? '¡No te pierdas ninguna trivia!',
            style: const TextStyle(
              fontFamily: 'ShellHeavy',
              fontSize: 16,
              color: Color(0xFF0F5132),
            ),
          ),
          if (howTo != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => ComoParticiparPage(howToParticipate: howTo),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Descubre cómo participar',
                      style: TextStyle(
                        fontFamily: 'ShellHeavy',
                        fontSize: 14,
                        color: Color(0xFF0F5132),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Color(0xFF0F5132), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: widget.dynamic.available ? () => _openCta(context) : null,
        icon: _buildCtaIcon(),
        label: Text(
          widget.dynamic.available
              ? (widget.dynamic.ctaText ?? 'Ir')
              : 'No disponible',
          style: const TextStyle(
            fontFamily: 'ShellHeavy',
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

/// Icono personalizado de Instagram dibujado vectorialmente con widgets de Flutter.
class _InstagramIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _InstagramIcon({this.size = 20, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.8),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
