import 'package:flutter/material.dart';

class AppColors {
  static const brandPrimary = Color(0xFF111827);
  static const brandAccent = Color(0xFF10B981);
  static const brandAccentDark = Color(0xFF047857);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const surfaceBg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD1D5DB);
  static const textPrimary = Color(0xFF111827);
  static const textMuted = Color(0xFF374151);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF059669);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandAccent,
      onPrimary: Colors.white,
      secondary: AppColors.brandAccent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.red,
      onError: Colors.white,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandAccent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brandAccent : AppColors.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            color: selected ? AppColors.brandAccent : AppColors.textMuted,
          );
        }),
      ),
    );
  }
}
