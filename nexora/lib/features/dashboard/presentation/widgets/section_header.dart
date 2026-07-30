import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onVerTodos;

  const SectionHeader({super.key, required this.title, required this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onVerTodos,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.brandAccent,
            textStyle: const TextStyle(fontSize: 13),
          ),
          child: const Text('Ver todos'),
        ),
      ],
    );
  }
}
