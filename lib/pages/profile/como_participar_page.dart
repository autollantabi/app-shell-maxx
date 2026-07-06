import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class ComoParticiparPage extends StatelessWidget {
  const ComoParticiparPage({super.key});

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
          '¿Cómo participar?',
          style: TextStyle(
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
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado visual
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.green[700],
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '¡Conviértete en un experto y gana!',
                  style: TextStyle(
                    fontFamily: 'ShellHeavy',
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Por cada quizz correcto podrás ganar hasta 399 puntos para tu App Shell Maxx.',
                  style: TextStyle(
                    fontFamily: 'ShellBook',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Pasos detallados
              _buildStepCard(
                stepNumber: '1',
                title: '¡Síguenos!',
                descriptionWidget: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'ShellBook',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Siguenos en nuestra cuenta oficial en instragram ',
                      ),
                      TextSpan(
                        text: '@shell.lubricantes.ec.md',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontFamily: 'ShellHeavy',
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final Uri url = Uri.parse(
                              'https://www.instagram.com/shell.lubricantes.ec.md/',
                            );
                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (e) {
                              debugPrint('Error launching Instagram: $e');
                            }
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                icon: Icons.notifications_active_outlined,
              ),
              _buildStepCard(
                stepNumber: '2',
                title: '¡Participa!',
                description:
                    'Completa las trivias que dejaremos en stories los días jueves.',
                icon: Icons.quiz_outlined,
              ),
              _buildStepCard(
                stepNumber: '3',
                title: '¡Escríbenos!',
                description:
                    'Envíanos capturas de tu participación por whatsapp:\n• Respuesta al quizz (captura de cada storie con respuesta seleccionada)\n• Captura de tu perfil donde sea vea tu nombre de usuario',
                icon: Icons.stars_rounded,
              ),
              _buildStepCard(
                stepNumber: '4',
                title: '¡Gana puntos!',
                description:
                    'Una vez validada tu participación acreditaremos tus puntos.',
                icon: Icons.analytics_outlined,
              ),

              const SizedBox(height: 16),
              _buildWhatsAppSection(context),

              const SizedBox(height: 16),
              // Botón de Entendido
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontFamily: 'ShellHeavy', fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    String? description,
    Widget? descriptionWidget,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ShellHeavy',
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'ShellHeavy',
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                descriptionWidget ??
                    Text(
                      description ?? '',
                      style: const TextStyle(
                        fontFamily: 'ShellBook',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSection(BuildContext context) {
    const String phoneNumber = '+593 98 157 2069';
    const String cleanNumber = '593981572069';
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    Future<void> openWhatsApp() async {
      try {
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir WhatsApp'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir WhatsApp: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.green[100]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Envío por WhatsApp',
                  style: TextStyle(
                    fontFamily: 'ShellHeavy',
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Envía tus capturas de pantallas al número de Club Shell Maxx:',
            style: TextStyle(
              fontFamily: 'ShellBook',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: openWhatsApp,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  SelectableText(
                    phoneNumber,
                    onTap: openWhatsApp,
                    style: TextStyle(
                      fontFamily: 'ShellHeavy',
                      fontSize: 15,
                      color: Colors.green[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: openWhatsApp,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                'Abrir WhatsApp',
                style: TextStyle(
                  fontFamily: 'ShellHeavy',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textPrimary,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
