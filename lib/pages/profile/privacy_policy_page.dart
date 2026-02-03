import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Condiciones y políticas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontFamily: 'ShellHeavy',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'ShellHeavy',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Última actualización: $_lastUpdate',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'ShellBook',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            _buildSection(
              title: '1. Información que recopilamos',
              content:
                  'Recopilamos información que usted nos proporciona directamente, incluyendo:\n\n'
                  '• Información de cuenta (nombre, correo electrónico, contraseña)\n'
                  '• Información de perfil (foto, dirección, número de teléfono)\n'
                  '• Información de transacciones y puntos\n'
                  '• Información de uso de la aplicación',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '2. Uso de la información',
              content:
                  'Utilizamos la información recopilada para:\n\n'
                  '• Proporcionar, mantener y mejorar nuestros servicios\n'
                  '• Procesar transacciones y gestionar puntos\n'
                  '• Enviar notificaciones y comunicaciones importantes\n'
                  '• Personalizar su experiencia en la aplicación\n'
                  '• Detectar y prevenir fraudes',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '3. Compartir información',
              content:
                  'No vendemos su información personal. Podemos compartir información en las siguientes circunstancias:\n\n'
                  '• Con su consentimiento explícito\n'
                  '• Para cumplir con obligaciones legales\n'
                  '• Con proveedores de servicios que nos ayudan a operar la aplicación\n'
                  '• En caso de fusión, adquisición o venta de activos',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '4. Seguridad de los datos',
              content:
                  'Implementamos medidas de seguridad técnicas y organizativas apropiadas para proteger su información personal contra acceso no autorizado, alteración, divulgación o destrucción.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '5. Sus derechos',
              content:
                  'Usted tiene derecho a:\n\n'
                  '• Acceder a su información personal\n'
                  '• Corregir información inexacta\n'
                  '• Solicitar la eliminación de sus datos\n'
                  '• Oponerse al procesamiento de sus datos\n'
                  '• Portabilidad de datos',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '6. Cookies y tecnologías similares',
              content:
                  'Utilizamos cookies y tecnologías similares para mejorar su experiencia, analizar el uso de la aplicación y personalizar el contenido.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '7. Cambios a esta política',
              content:
                  'Podemos actualizar esta política de privacidad ocasionalmente. Le notificaremos sobre cambios significativos publicando la nueva política en esta página y actualizando la fecha de "Última actualización".',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '8. Contacto',
              content:
                  'Si tiene preguntas sobre esta política de privacidad, puede contactarnos a través de:\n\n'
                  '• Correo electrónico: soporte@ejemplo.com\n'
                  '• Teléfono: +593 XXX XXX XXX',
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Términos y Condiciones',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'ShellHeavy',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. Aceptación de los términos',
              content:
                  'Al acceder y utilizar esta aplicación, usted acepta cumplir con estos términos y condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar la aplicación.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '2. Uso de la aplicación',
              content:
                  'Usted se compromete a:\n\n'
                  '• Utilizar la aplicación solo para fines legales\n'
                  '• No interferir con el funcionamiento de la aplicación\n'
                  '• No intentar acceder a áreas restringidas\n'
                  '• Mantener la confidencialidad de su cuenta',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '3. Cuentas de usuario',
              content:
                  'Es responsable de mantener la confidencialidad de su cuenta y contraseña. Usted acepta notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '4. Propiedad intelectual',
              content:
                  'Todo el contenido de la aplicación, incluyendo textos, gráficos, logos, iconos, imágenes y software, es propiedad de la empresa o sus proveedores de contenido y está protegido por leyes de propiedad intelectual.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '5. Limitación de responsabilidad',
              content:
                  'La aplicación se proporciona "tal cual" sin garantías de ningún tipo. No garantizamos que la aplicación esté libre de errores o interrupciones.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '6. Modificaciones',
              content:
                  'Nos reservamos el derecho de modificar, suspender o discontinuar cualquier aspecto de la aplicación en cualquier momento sin previo aviso.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'ShellHeavy',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'ShellBook',
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  static const String _lastUpdate = '25 de noviembre de 2025';
}
