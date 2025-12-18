import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PointsHistoryPage extends StatelessWidget {
  const PointsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo de transacciones
    final transactions = [
      {
        'date': 'Hoy, 00:00',
        'product': '3 litros Shell Helix 10w40',
        'points': 5,
        'type': 'Full sintético',
        'isNegative': false,
      },
      {
        'date': 'Hoy, 00:00',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': 'Hoy, 00:00',
        'product': '3 litros Shell Helix 10w40',
        'points': 5,
        'type': 'Full sintético',
        'isNegative': false,
      },
      {
        'date': 'Hoy, 00:00',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '12/08/2025',
        'product': '-3 litros Shell Helix HX5 20W-50',
        'points': -5,
        'type': 'Full sintético',
        'isNegative': true,
        'note': 'Nota de crédito',
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix 10w40',
        'points': 5,
        'type': 'Full sintético',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
      {
        'date': '11/08/2025',
        'product': '3 litros Shell Helix HX5 20W-50',
        'points': 3,
        'type': 'Mineral',
        'isNegative': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Puntos acumulados',
          style: TextStyle(fontSize: 18, fontFamily: 'ShellBold', color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final isNegative = transaction['isNegative'] as bool;
          final points = transaction['points'] as int;
          final color = isNegative ? AppColors.error : AppColors.success;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: Fecha y producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fecha
                      Text(
                        transaction['date'] as String,
                        style: TextStyle(fontSize: 14, fontFamily: 'ShellTHAI'),
                      ),
                      const SizedBox(height: 1),
                      // Producto
                      Text(
                        transaction['product'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'ShellTHAI',
                          color: isNegative
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                      // Nota de crédito si aplica
                      if (transaction['note'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          transaction['note'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'ShellTHAI',
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Columna derecha: Puntos y tipo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${points > 0 ? '+' : ''}$points puntos',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'ShellTHAI',
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Tipo de producto con ícono
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícono según el tipo
                        transaction['type'] == 'Full sintético'
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isNegative
                                      ? AppColors.error
                                      : AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: isNegative
                                        ? AppColors.error
                                        : AppColors.success,
                                    width: 1.5,
                                  ),
                                ),
                                transform: Matrix4.rotationZ(
                                  0.785398,
                                ), // 45 grados para formar diamante
                              ),
                        const SizedBox(width: 6),
                        Text(
                          transaction['type'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'ShellTHAI',
                            color: isNegative
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
