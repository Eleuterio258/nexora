import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class EmptyStateText extends StatelessWidget {
  final String text;

  const EmptyStateText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
    );
  }
}
