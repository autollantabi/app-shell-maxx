import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../layouts/main_layout.dart';

class OnboardingPage extends StatefulWidget {
  final UserModel user;

  const OnboardingPage({super.key, required this.user});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'title': 'Tu camino al liderazgo\ncomienza aquí',
      'description':
          'Cada paso, cada logro en tu día a día, suma\npara llevarte más lejos.',
      'image': 'assets/images/app/onboarding1.png',
    },
    {
      'title': 'Liderar también se premia',
      'description':
          'Tu dedicación se transforma en experiencias, reconocimientos y momentos que valen la pena.',
      'image': 'assets/images/app/onboarding2.png',
    },
    // {
    //   'title': 'Aquí nacen los líderes\nShell',
    //   'description': 'Una comunidad que avanza, crece y lidera el\ncamino.',
    //   'description1': '¿Estás listo para ser parte?',
    //   'image': 'assets/images/app/onboarding3.png',
    // },
    {
      'title': 'Potencia que inspira',
      'description':
          'La misma fuerza que impulsa a los campeones\ntambién impulsa tu camino.',
      'description1': 'Con Shell, tu motor gana... y tú también.',
      'image': 'assets/images/app/onboarding4.png',
    },
    {
      'title': '19 años siendo #1 en\nlubricantes',
      'description':
          'Ahora, tú eres parte de ese liderazgo: acumula\npuntos y desbloquea recompensas.',
      'image': 'assets/images/app/onboarding5.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    // El onboarding se completa automáticamente cuando el usuario inicia sesión
    // y el backend actualiza LAST_LOGIN. No necesitamos guardar nada localmente.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainLayout(user: widget.user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView con el contenido de cada página
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _onboardingPages.length,
              itemBuilder: (context, index) {
                final page = _onboardingPages[index];
                return _buildOnboardingPage(page);
              },
            ),
            // Indicadores y botón fijos en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicadores de página
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingPages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? AppColors.primary
                                : Colors.grey[700],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón siempre presente pero con fade in en la última página
                    AnimatedOpacity(
                      opacity: _currentPage == _onboardingPages.length - 1
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _currentPage == _onboardingPages.length - 1
                              ? _completeOnboarding
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Comenzar',
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
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración
          Expanded(
            flex: 3,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Imagen (más grande para que sobresalga)
                  Image.asset(
                    page['image'] as String,
                    fit: BoxFit.contain,
                    width: 300,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Texto
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 100.0,
              ), // Espacio para los indicadores fijos
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    page['title'] as String,
                    style: const TextStyle(
                      fontSize: 22,
                      fontFamily: 'ShellBold',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page['description'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'ShellBook',
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  if (page['description1'] != null)
                    _buildDescription1(page['description1'] as String),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription1(String text) {
    // Buscar la posición de "y tú también" en el texto
    final highlightText = 'y tú también';
    final index = text.toLowerCase().indexOf(highlightText.toLowerCase());

    if (index == -1) {
      // Si no se encuentra, mostrar el texto normal
      return Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'ShellBold',
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        textAlign: TextAlign.left,
      );
    }

    // Dividir el texto en partes
    final beforeText = text.substring(0, index);
    final highlightTextActual = text.substring(
      index,
      index + highlightText.length,
    );
    final afterText = text.substring(index + highlightText.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: beforeText,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'ShellBold',
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: highlightTextActual,
            style: const TextStyle(
              fontSize: 19,
              fontFamily: 'ShellBold',
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (afterText.isNotEmpty)
            TextSpan(
              text: afterText,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'ShellBold',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.left,
    );
  }
}
