import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AssiduidadeCard extends StatelessWidget {
  final String diasTrabalhados;
  final String horas;

  const AssiduidadeCard({
    super.key,
    required this.diasTrabalhados,
    required this.horas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.access_time_outlined, size: 20, color: AppColors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Assiduidade',
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
          diasTrabalhados,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 1),
        Text(horas, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
