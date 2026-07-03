import 'package:flutter/material.dart';

/// Design tokens baseados no guia de mockups E258Tech.
/// Material Design 3, identidade Emerald Green, layout sem bordas.
class AppColors {
  AppColors._();

  // ── Primárias ──────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF10B981);
  static const Color onPrimary    = Color(0xFFFFFFFF);
  static const Color primaryDark  = Color(0xFF047857);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color mintContainer = Color(0xFFF0FDF4);

  // ── Superfícies ────────────────────────────────────────────────────────────
  static const Color background      = Color(0xFFF8FAFC);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF1F5F9);

  // ── Texto ──────────────────────────────────────────────────────────────────
  static const Color textDark    = Color(0xFF111827);
  static const Color textGray    = Color(0xFF374151);
  static const Color textLight   = Color(0xFFFFFFFF);
  static const Color onSurface   = Color(0xFF111827);

  // ── Estados ────────────────────────────────────────────────────────────────
  static const Color success    = Color(0xFF059669);
  static const Color onSuccess  = Color(0xFFFFFFFF);
  static const Color error      = Color(0xFFEF4444);
  static const Color onError    = Color(0xFFFFFFFF);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color info       = Color(0xFF3B82F6);

  // ── Neutros ────────────────────────────────────────────────────────────────
  static const Color outline      = Color(0xFFE5E7EB);
  static const Color divider      = Color(0xFFF3F4F6);
  static const Color disabled     = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);
}
