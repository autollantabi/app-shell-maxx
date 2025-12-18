import 'package:flutter/material.dart';

class AppColors {
  // Colores principales de Shell
  static const Color primary = Color(0xFFDD1D21); // Rojo Shell
  static const Color primaryLight = Color(0xFFFF4C4F);
  static const Color primaryDark = Color(0xFFB01418);

  // Colores secundarios de Shell
  static const Color secondary = Color(0xFFFBCE07); // Amarillo Shell
  static const Color secondaryLight = Color(0xFFFFE14D);
  static const Color secondaryDark = Color(0xFFC79F00);

  // Colores de acento
  static const Color accent = Color(0xFFFBCE07); // Amarillo Shell
  static const Color accentLight = Color(0xFFFFE14D);
  static const Color accentDark = Color(0xFFC79F00);

  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // Colores de texto
  static const Color textPrimary = Color(0xFF4A4A4A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Colores de borde
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Colores de sombra
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);

  // Colores para tipos de usuario
  static const Color adminColor = Color(0xFF9C27B0); // Púrpura para Admin
  static const Color managerColor = Color(0xFF2196F3); // Azul para Manager
  static const Color influencerColor = Color(
    0xFFFF6F00,
  ); // Naranja para Influencer

  static const Color cardBackground = Color(0xFFF8F8F8);

  // Mantener compatibilidad (userColor apunta a managerColor)
  static const Color userColor = managerColor;
  static const Color guestColor = influencerColor;
}
