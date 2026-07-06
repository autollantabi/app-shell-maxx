import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import 'como_participar_page.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../models/user_model.dart';
import '../../layouts/main_layout.dart';
import 'participaciones_page.dart';
import '../../api.dart';

class TriviaFutboleraPage extends StatefulWidget {
  final UserModel user;
  const TriviaFutboleraPage({super.key, required this.user});

  @override
  State<TriviaFutboleraPage> createState() => _TriviaFutboleraPageState();
}

class _TriviaFutboleraPageState extends State<TriviaFutboleraPage> {
  static const String _instagramQuizUrl =
      'https://www.instagram.com/shell.lubricantes.ec.md/';

  bool _isLoading = true;
  int _triviaPoints = 0;
  int _completedQuizzes = 0;
  int _totalQuizzes = 6;
  double _progressPercentage = 0.0;
  final String seasonDateRange = 'Del 01 de junio al 15 de julio de 2026';

  @override
  void initState() {
    super.initState();
    _fetchTriviaData();
  }

  Future<void> _fetchTriviaData() async {
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
                : int.tryParse(data['TOTAL_TRIVIAS'].toString()) ?? 6;

            final double rawPercentage = data['PORCENTAJE_COMPLETADO'] is num
                ? (data['PORCENTAJE_COMPLETADO'] as num).toDouble()
                : double.tryParse(data['PORCENTAJE_COMPLETADO'].toString()) ??
                      0.0;

            _progressPercentage = rawPercentage / 100.0;

            _triviaPoints = data['PUNTOS_EXTRA_ACUMULADOS'] is int
                ? data['PUNTOS_EXTRA_ACUMULADOS']
                : int.tryParse(data['PUNTOS_EXTRA_ACUMULADOS'].toString()) ?? 0;

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

  Future<void> _openInstagramQuiz(BuildContext context) async {
    final uri = Uri.parse(_instagramQuizUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Instagram'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Trivias futboleras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'ShellHeavy',
            ),
          ),
          backgroundColor: Colors.green[700],
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final int triviaPoints = _triviaPoints;
    final int completedQuizzes = _completedQuizzes;
    final int totalQuizzes = _totalQuizzes;
    final double progressPercentage = _progressPercentage;
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Trivias futboleras',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.green[700], // Background verde premium
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTriviaData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado debajo de la AppBar
              Container(
                width: double.infinity,
                height: 180,
                decoration: const BoxDecoration(color: Colors.white),
                child: Image.asset(
                  'assets/images/app/EncabezadoTriviaFutbolera.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.green[800],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              size: 64,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Trivia Semanal Shell',
                              style: TextStyle(
                                fontFamily: 'ShellHeavy',
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta premium de Puntos Acumulados
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => ParticipacionesPage(
                                triviaPoints: triviaPoints,
                                user: user,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors
                                .green[700], // Background verde premium para todo el panel
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
                              // Copa blanca con fondo rojo a la izquierda de los puntos
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary, // Fondo rojo
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emoji_events, // Icono de copa
                                  color: Colors.white, // Icono blanco
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Información de los puntos acumulados
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Puntos acumulados por trivias',
                                      style: TextStyle(
                                        fontFamily: 'ShellBook',
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$triviaPoints',
                                      style: const TextStyle(
                                        fontFamily: 'ShellHeavy',
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta premium de Temporada Actual
                    Container(
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
                          // Título y fecha de temporada
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
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
                                      seasonDateRange,
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

                          // Barra de progreso y texto de quizzes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tu participación: $completedQuizzes de $totalQuizzes',
                                style: const TextStyle(
                                  fontFamily: 'ShellHeavy',
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${(progressPercentage * 100).toInt()}%',
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
                              value: progressPercentage,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green[700]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta informativa premium
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFC8E6C9,
                        ), // Fondo verde más visible (Green 100)
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '¡No te pierdas ninguna trivia!',
                                  style: TextStyle(
                                    fontFamily: 'ShellHeavy',
                                    fontSize: 16,
                                    color: Color(
                                      0xFF0F5132,
                                    ), // Texto verde oscuro premium
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      const ComoParticiparPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Descubre cómo participar',
                                    style: TextStyle(
                                      fontFamily: 'ShellHeavy',
                                      fontSize: 14,
                                      color: Color(
                                        0xFF0F5132,
                                      ), // Texto verde oscuro premium enlace
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: const Color(
                                      0xFF0F5132,
                                    ), // Flecha verde oscuro
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón de Ir al quiz de esta semana (Ubicado debajo del todo)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _openInstagramQuiz(context),
                        icon: const _InstagramIcon(
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        label: const Text(
                          'Ir a Instagram',
                          style: TextStyle(
                            fontFamily: 'ShellHeavy',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
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
}

// Icono personalizado de Instagram dibujado vectorialmente con widgets de Flutter
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
