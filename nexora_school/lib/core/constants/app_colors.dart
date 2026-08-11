import 'package:flutter/material.dart';

/// Tema de cores mutável, carregado a partir do branding remoto.
@immutable
class AppColorsTheme {
  const AppColorsTheme({
    required this.primary,
    required this.onPrimary,
    required this.primaryDark,
    required this.primaryLight,
    required this.mintContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textDark,
    required this.textGray,
    required this.textLight,
    required this.onSurface,
    required this.success,
    required this.onSuccess,
    required this.error,
    required this.onError,
    required this.warning,
    required this.info,
    required this.outline,
    required this.divider,
    required this.disabled,
    required this.disabledText,
  });

  static const AppColorsTheme defaultTheme = AppColorsTheme(
    primary: Color(0xFF10B981),
    onPrimary: Color(0xFFFFFFFF),
    primaryDark: Color(0xFF047857),
    primaryLight: Color(0xFFD1FAE5),
    mintContainer: Color(0xFFF0FDF4),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    textDark: Color(0xFF111827),
    textGray: Color(0xFF374151),
    textLight: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111827),
    success: Color(0xFF059669),
    onSuccess: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    outline: Color(0xFFE5E7EB),
    divider: Color(0xFFF3F4F6),
    disabled: Color(0xFFD1D5DB),
    disabledText: Color(0xFF9CA3AF),
  );

  final Color primary;
  final Color onPrimary;
  final Color primaryDark;
  final Color primaryLight;
  final Color mintContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textDark;
  final Color textGray;
  final Color textLight;
  final Color onSurface;
  final Color success;
  final Color onSuccess;
  final Color error;
  final Color onError;
  final Color warning;
  final Color info;
  final Color outline;
  final Color divider;
  final Color disabled;
  final Color disabledText;

  AppColorsTheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryDark,
    Color? primaryLight,
    Color? mintContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textDark,
    Color? textGray,
    Color? textLight,
    Color? onSurface,
    Color? success,
    Color? onSuccess,
    Color? error,
    Color? onError,
    Color? warning,
    Color? info,
    Color? outline,
    Color? divider,
    Color? disabled,
    Color? disabledText,
  }) {
    return AppColorsTheme(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      mintContainer: mintContainer ?? this.mintContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textDark: textDark ?? this.textDark,
      textGray: textGray ?? this.textGray,
      textLight: textLight ?? this.textLight,
      onSurface: onSurface ?? this.onSurface,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      outline: outline ?? this.outline,
      divider: divider ?? this.divider,
      disabled: disabled ?? this.disabled,
      disabledText: disabledText ?? this.disabledText,
    );
  }
}

/// Design tokens baseados no guia de mockups E258Tech.
/// Material Design 3, identidade Emerald Green por omissão.
/// As cores primárias são mutáveis em runtime via [update].
class AppColors {
  AppColors._();

  static final ValueNotifier<AppColorsTheme> _theme =
      ValueNotifier(AppColorsTheme.defaultTheme);

  static ValueNotifier<AppColorsTheme> get notifier => _theme;

  static AppColorsTheme get theme => _theme.value;

  // ── Primárias (mutáveis) ───────────────────────────────────────────────────
  static Color get primary => _theme.value.primary;
  static Color get onPrimary => _theme.value.onPrimary;
  static Color get primaryDark => _theme.value.primaryDark;
  static Color get primaryLight => _theme.value.primaryLight;
  static Color get mintContainer => _theme.value.mintContainer;

  // ── Superfícies ────────────────────────────────────────────────────────────
  static Color get background => _theme.value.background;
  static Color get surface => _theme.value.surface;
  static Color get surfaceVariant => _theme.value.surfaceVariant;

  // ── Texto ──────────────────────────────────────────────────────────────────
  static Color get textDark => _theme.value.textDark;
  static Color get textGray => _theme.value.textGray;
  static Color get textLight => _theme.value.textLight;
  static Color get onSurface => _theme.value.onSurface;

  // ── Estados ────────────────────────────────────────────────────────────────
  static Color get success => _theme.value.success;
  static Color get onSuccess => _theme.value.onSuccess;
  static Color get error => _theme.value.error;
  static Color get onError => _theme.value.onError;
  static Color get warning => _theme.value.warning;
  static Color get info => _theme.value.info;

  // ── Neutros ────────────────────────────────────────────────────────────────
  static Color get outline => _theme.value.outline;
  static Color get divider => _theme.value.divider;
  static Color get disabled => _theme.value.disabled;
  static Color get disabledText => _theme.value.disabledText;

  /// Atualiza o tema de cores e notifica todos os listeners.
  static void update(AppColorsTheme theme) => _theme.value = theme;
}