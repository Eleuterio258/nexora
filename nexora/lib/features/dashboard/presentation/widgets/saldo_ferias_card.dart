import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SaldoFeriasCard extends StatelessWidget {
  final String dias;
  final String total;

  const SaldoFeriasCard({super.key, required this.dias, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Saldo de Férias',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          dias,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(total, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
