import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../layouts/main_layout.dart';
import '../../api.dart';

class ParticipacionesPage extends StatefulWidget {
  final int triviaPoints;
  final UserModel user;

  const ParticipacionesPage({
    super.key,
    required this.triviaPoints,
    required this.user,
  });

  @override
  State<ParticipacionesPage> createState() => _ParticipacionesPageState();
}

class _ParticipacionesPageState extends State<ParticipacionesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _participaciones = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipaciones();
  }

  Future<void> _fetchParticipaciones() async {
    try {
      final response = await ApiConfig.getResponse(
        '/influencer-dynamics/app/my-trivias',
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is List) {
          final List<Map<String, dynamic>> parsedList = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final dynamicData =
                  item['DYNAMIC'] as Map<String, dynamic>? ?? {};
              parsedList.add({
                'title': dynamicData['NAME'] ?? 'Trivia',
                'date': _formatDate(item['CREATEDAT']?.toString() ?? ''),
                'correctAnswers':
                    '${item['COMPLETED_COUNT'] ?? 0} respuesta/s correctas',
                'points': item['EXTRA_POINTS'] ?? 0,
              });
            }
          }
          if (mounted) {
            setState(() {
              _participaciones = parsedList;
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

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Sin fecha';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoString.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final triviaPoints = widget.triviaPoints;
    final user = widget.user;
    final participaciones = _participaciones;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.green[800],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Mis participaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'ShellHeavy',
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green[800], // Fondo de verde
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mis participaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchParticipaciones,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de puntos acumulados en formato premium
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Puntos totales acumulados',
                          style: TextStyle(
                            fontFamily: 'ShellBook',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$triviaPoints',
                          style: const TextStyle(
                            fontFamily: 'ShellHeavy',
                            fontSize: 36,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Historial de participaciones
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Historial de trivias',
                        style: TextStyle(
                          fontFamily: 'ShellHeavy',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Listado de participaciones
                  if (participaciones.isEmpty)
                    _buildEmptyState()
                  else
                    ...participaciones.map(
                      (part) => _buildParticipationItem(part),
                    ),

                  const SizedBox(height: 24),
                  // Botón de Ir al quiz de esta semana
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
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

  Widget _buildParticipationItem(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'ShellHeavy',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['date']} • ${item['correctAnswers']}',
                  style: TextStyle(
                    fontFamily: 'ShellBook',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Puntos ganados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${item['points']} pts',
              style: const TextStyle(
                fontFamily: 'ShellHeavy',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes participaciones',
            style: TextStyle(
              fontFamily: 'ShellHeavy',
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Completa las trivias semanales en Instagram y envía tus capturas para acumular puntos.',
            style: TextStyle(
              fontFamily: 'ShellBook',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static const String _instagramQuizUrl =
      'https://www.instagram.com/shell.lubricantes.ec.md/';

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
