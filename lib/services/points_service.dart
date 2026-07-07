import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../api/points_api.dart';
import '../widgets/points_popup.dart';

class PointsService {
  /// Consulta si el usuario tiene un regalo de puntos pendiente (asignado desde el
  /// front administrativo). Si existe, muestra el [PointsPopup] para que lo canjee.
  ///
  /// Este flujo es totalmente independiente del de cumpleaños: no comparte estado ni
  /// caché con BirthdayService y decide por su cuenta si mostrar su modal.
  static Future<void> checkAndShowPointsGift(
    BuildContext context,
    UserModel user, {
    VoidCallback? onRefresh,
  }) async {
    try {
      final response = await PointsApi.getMyGiftPoints();

      if (!response.success || response.data == null) return;

      final gifts = response.data!['gifts'] as List?;
      if (gifts == null || gifts.isEmpty) return;

      // Se muestra el primer regalo pendiente (el más antiguo).
      final gift = gifts.first as Map<String, dynamic>;
      final giftId = gift['giftId']?.toString();
      final points = (gift['pointsToRedeem'] as num?)?.toInt() ?? 0;

      if (giftId == null || points <= 0) return;

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) => PointsPopup(
            user: user,
            giftId: giftId,
            points: points,
            onRefresh: onRefresh,
          ),
        );
      }
    } catch (e) {
      // Si algo falla, simplemente no se muestra el regalo.
    }
  }
}
