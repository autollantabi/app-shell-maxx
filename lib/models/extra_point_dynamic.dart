import 'package:flutter/material.dart';

/// Un paso del instructivo "cómo participar".
class ParticipateStep {
  final String iconKey;
  final String title;
  final String description;
  final List<String> bullets;

  const ParticipateStep({
    required this.iconKey,
    required this.title,
    required this.description,
    required this.bullets,
  });

  factory ParticipateStep.fromJson(Map<String, dynamic> json) {
    return ParticipateStep(
      iconKey: json['icon']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      bullets: (json['bullets'] is List)
          ? (json['bullets'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

/// Bloque de contacto del instructivo (p.ej. WhatsApp).
class ParticipateContact {
  final String type;
  final String title;
  final String label;
  final String value;
  final String buttonText;

  const ParticipateContact({
    required this.type,
    required this.title,
    required this.label,
    required this.value,
    required this.buttonText,
  });

  factory ParticipateContact.fromJson(Map<String, dynamic> json) {
    return ParticipateContact(
      type: json['type']?.toString() ?? 'whatsapp',
      title: json['title']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? '',
    );
  }
}

/// Instructivo "cómo participar" configurable por trivia (viene del back).
class HowToParticipate {
  final String headerIconKey;
  final String title;
  final String subtitle;
  final List<ParticipateStep> steps;
  final ParticipateContact? contact;

  const HowToParticipate({
    required this.headerIconKey,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.contact,
  });

  factory HowToParticipate.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    final contactJson = json['contact'];
    return HowToParticipate(
      headerIconKey: json['headerIcon']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      steps: (stepsJson is List)
          ? stepsJson
                .whereType<Map<String, dynamic>>()
                .map(ParticipateStep.fromJson)
                .toList()
          : const [],
      contact: (contactJson is Map<String, dynamic>)
          ? ParticipateContact.fromJson(contactJson)
          : null,
    );
  }
}

/// Representa una tarjeta de la pantalla "Gana puntos extras".
/// Los datos vienen del back (GET /influencer-dynamics/app/extra-points).
class ExtraPointDynamic {
  final int id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String badgeColorKey;
  final String iconKey;
  final String type;

  /// URL del CTA (mapea desde INSTAGRAM_QUIZ_URL del back).
  final String? ctaUrl;
  final bool active;
  final DateTime? startDate;
  final DateTime? endDate;
  final int sortOrder;

  /// Calculado por el back: activo y dentro de la ventana de fechas.
  final bool available;

  // Contenido administrable desde el back.
  final String? iconUrl;
  final String? headerImageUrl;
  final String? detailDescription;
  final String? ctaText;
  final String? ctaIconKey;
  final bool showsProgress;
  final HowToParticipate? howToParticipate;

  const ExtraPointDynamic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColorKey,
    required this.iconKey,
    required this.type,
    required this.ctaUrl,
    required this.active,
    required this.startDate,
    required this.endDate,
    required this.sortOrder,
    required this.available,
    required this.iconUrl,
    required this.headerImageUrl,
    required this.detailDescription,
    required this.ctaText,
    required this.ctaIconKey,
    required this.showsProgress,
    required this.howToParticipate,
  });

  factory ExtraPointDynamic.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    String? nullableString(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      return str.isEmpty ? null : str;
    }

    final howToJson = json['HOW_TO_PARTICIPATE'];

    return ExtraPointDynamic(
      id: parseInt(json['ID']),
      title: json['TITLE']?.toString() ?? '',
      subtitle: json['SUBTITLE']?.toString() ?? '',
      badgeText: json['BADGE_TEXT']?.toString() ?? '',
      badgeColorKey: json['BADGE_COLOR']?.toString() ?? '',
      iconKey: json['ICON_KEY']?.toString() ?? '',
      type: json['TYPE']?.toString() ?? '',
      ctaUrl: nullableString(json['INSTAGRAM_QUIZ_URL']),
      active: json['ACTIVE'] == true || json['ACTIVE']?.toString() == '1',
      startDate: parseDate(json['START_DATE']),
      endDate: parseDate(json['END_DATE']),
      sortOrder: parseInt(json['SORT_ORDER']),
      available: json['AVAILABLE'] == true,
      iconUrl: nullableString(json['ICON_URL']),
      headerImageUrl: nullableString(json['HEADER_IMAGE_URL']),
      detailDescription: nullableString(json['DETAIL_DESCRIPTION']),
      ctaText: nullableString(json['CTA_TEXT']),
      ctaIconKey: nullableString(json['CTA_ICON']),
      showsProgress:
          json['SHOWS_PROGRESS'] == true || json['SHOWS_PROGRESS']?.toString() == '1',
      howToParticipate: (howToJson is Map<String, dynamic>)
          ? HowToParticipate.fromJson(howToJson)
          : null,
    );
  }

  /// Ruta del asset local a partir de la clave del ícono (fallback si no hay iconUrl).
  String get iconAssetPath => 'assets/images/icons/$iconKey.png';

  /// Mapea la clave de color del back a un Color de Flutter.
  Color get badgeColor {
    switch (badgeColorKey.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'brown':
        return Colors.brown;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
