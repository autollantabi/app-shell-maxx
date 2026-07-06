import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/birthday_popup.dart';

class BirthdayService {
  /// Verifica si es el cumpleaños del usuario y si ya se mostró el regalo hoy.
  /// Si es el cumpleaños y no se ha mostrado, abre el popup.
  static Future<void> checkAndShowBirthdayGift(
    BuildContext context,
    UserModel user, {
    VoidCallback? onRefresh,
  }) async {
    if (user.yaCanjeoRecompensaAnual) return;
    if (user.dateOfBirth == null) return;

    final now = DateTime.now();
    final birthday = user.dateOfBirth!;

    // Verificar si hoy es el cumpleaños (mismo mes y día)
    final isBirthday = birthday.day == now.day && birthday.month == now.month;

    if (!isBirthday) return;

    // Mostrar el popup
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) =>
            BirthdayPopup(user: user, onRefresh: onRefresh),
      );

      // Guardar que ya se mostró hoy
    }
  }
}
