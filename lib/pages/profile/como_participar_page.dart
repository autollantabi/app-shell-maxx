import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../models/extra_point_dynamic.dart';

/// Instructivo "¿Cómo participar?" configurable por trivia.
/// Recibe un [HowToParticipate] (del back). Si llega null, usa el contenido
/// por defecto (el de la trivia futbolera) como fallback.
class ComoParticiparPage extends StatelessWidget {
  final HowToParticipate? howToParticipate;

  const ComoParticiparPage({super.key, this.howToParticipate});

  HowToParticipate get _content => howToParticipate ?? _defaultContent;

  static IconData _iconFor(String key) {
    switch (key.toLowerCase()) {
      case 'soccer':
        return Icons.sports_soccer;
      case 'notification':
        return Icons.notifications_active_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'star':
        return Icons.stars_rounded;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;

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
                    _iconFor(content.headerIconKey),
                    color: Colors.green[700],
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  content.title,
                  style: const TextStyle(
                    fontFamily: 'ShellHeavy',
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (content.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    content.subtitle,
                    style: const TextStyle(
                      fontFamily: 'ShellBook',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Pasos detallados
              ...content.steps.asMap().entries.map(
                (entry) => _buildStepCard(
                  stepNumber: '${entry.key + 1}',
                  step: entry.value,
                ),
              ),

              if (content.contact != null) ...[
                const SizedBox(height: 16),
                _buildContactSection(context, content.contact!),
              ],

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
    required ParticipateStep step,
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
                    Icon(_iconFor(step.iconKey), color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.title,
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
                Text(
                  step.description,
                  style: const TextStyle(
                    fontFamily: 'ShellBook',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (step.bullets.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...step.bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• $b',
                        style: const TextStyle(
                          fontFamily: 'ShellBook',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, ParticipateContact contact) {
    final cleanNumber = contact.value.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri targetUri = contact.type.toLowerCase() == 'whatsapp'
        ? Uri.parse('https://wa.me/$cleanNumber')
        : Uri.parse(contact.value);

    Future<void> openContact() async {
      try {
        if (await canLaunchUrl(targetUri)) {
          await launchUrl(targetUri, mode: LaunchMode.externalApplication);
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
                child: const Icon(Icons.chat, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contact.title,
                  style: const TextStyle(
                    fontFamily: 'ShellHeavy',
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (contact.label.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              contact.label,
              style: const TextStyle(
                fontFamily: 'ShellBook',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (contact.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: openContact,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        contact.value,
                        style: TextStyle(
                          fontFamily: 'ShellHeavy',
                          fontSize: 15,
                          color: Colors.green[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (contact.buttonText.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: openContact,
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                label: Text(
                  contact.buttonText,
                  style: const TextStyle(
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
        ],
      ),
    );
  }

  // Contenido por defecto (fallback) equivalente al instructivo actual de la trivia futbolera.
  static const HowToParticipate _defaultContent = HowToParticipate(
    headerIconKey: 'soccer',
    title: '¡Conviértete en un experto y gana!',
    subtitle:
        'Por cada quizz correcto podrás ganar hasta 399 puntos para tu App Shell Maxx.',
    steps: [
      ParticipateStep(
        iconKey: 'notification',
        title: '¡Síguenos!',
        description:
            'Síguenos en nuestra cuenta oficial en instagram @shell.lubricantes.ec.md',
        bullets: [],
      ),
      ParticipateStep(
        iconKey: 'quiz',
        title: '¡Participa!',
        description: 'Completa las trivias que dejaremos en stories los días jueves.',
        bullets: [],
      ),
      ParticipateStep(
        iconKey: 'star',
        title: '¡Escríbenos!',
        description: 'Envíanos capturas de tu participación por whatsapp:',
        bullets: [
          'Respuesta al quizz (captura de cada storie con respuesta seleccionada)',
          'Captura de tu perfil donde se vea tu nombre de usuario',
        ],
      ),
      ParticipateStep(
        iconKey: 'analytics',
        title: '¡Gana puntos!',
        description: 'Una vez validada tu participación acreditaremos tus puntos.',
        bullets: [],
      ),
    ],
    contact: ParticipateContact(
      type: 'whatsapp',
      title: 'Envío por WhatsApp',
      label: 'Envía tus capturas de pantallas al número de Club Shell Maxx:',
      value: '+593 98 157 2069',
      buttonText: 'Abrir WhatsApp',
    ),
  );
}
