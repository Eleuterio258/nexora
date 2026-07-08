import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.status,
    super.key,
  });

  final String label;
  final StatusBadgeType status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

enum StatusBadgeType {
  success,
  error,
  warning,
  neutral;

  Color get backgroundColor => switch (this) {
        success => const Color(0xFFE6F4F1),
        error => AppColors.primaryLight,
        warning => const Color(0xFFFEF3C7),
        neutral => const Color(0xFFEFF0F2),
      };

  Color get foregroundColor => switch (this) {
        success => AppColors.success,
        error => AppColors.error,
        warning => const Color(0xFFB45309),
        neutral => AppColors.dark,
      };
}
