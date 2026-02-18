import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

/// Pantalla que invita a formar parte del club y enlaza a viicommerce.com
class JoinClubPage extends StatelessWidget {
  const JoinClubPage({super.key});

  static const String _url = 'https://viicommerce.com';

  Future<void> _openViicommerce(BuildContext context) async {
    final uri = Uri.parse(_url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Forma parte del club',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'ShellHeavy',
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const _Paragraph(
                      'Club Shell Maxx es un programa exclusivo de fidelización e incentivos, diseñado para lubricadoras, talleres y socios comerciales que confían en Lubricantes Shell y los recomiendan día a día.',
                    ),
                    const SizedBox(height: 20),
                    const _Paragraph(
                      'Al formar parte del club, podrás acumular puntos por tus compras, acceder a beneficios especiales, experiencias, premios y herramientas que impulsan el crecimiento de tu negocio.',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Condiciones para formar parte de Club Shell Maxx:',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'ShellHeavy',
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BulletItem(
                      'Contar con un negocio activo que comercialice Lubricantes Shell.',
                    ),
                    _BulletItem(
                      'Realizar la compra de productos Shell a través de un distribuidor autorizado.',
                    ),
                    _BulletItem(
                      'Cumplir con un potencial de compra mínimo mensual (ponte en contacto con tu asesor para validar esta información).',
                    ),
                    _BulletItem(
                      'Mantener una ubicación comercial activa dentro del territorio ecuatoriano.',
                    ),
                    _BulletItem(
                      'Estar al día en sus compromisos comerciales y de facturación.',
                    ),
                    const SizedBox(height: 20),
                    const _Paragraph(
                      'Si cumples con los requisitos, ponte en contacto con tu asesor encargado e inicia tu registro en nuestro portal de distribuidores.',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openViicommerce(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'ShellHeavy',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'ShellBook',
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'ShellBook',
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'ShellBook',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
