import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  /// Vermelho principal do logotipo Nexora Pay.
  static const Color primary = Color(0xFFE51116);

  /// Vermelho escuro para estados hover/pressed ou destaques fortes.
  static const Color primaryDark = Color(0xFFB42318);

  /// Vermelho muito claro para fundos de avatares, badges e acentos suaves.
  static const Color primaryLight = Color(0xFFFCE5E6);

  /// Azul-escuro/quase preto do logotipo, usado para textos principais.
  static const Color dark = Color(0xFF121925);

  /// Cinza médio derivado do logotipo, para bordas e ícones secundários.
  static const Color grey = Color(0xFFACAEB4);

  /// Cinza claro para bordas e divisores.
  static const Color greyLight = Color(0xFFD1D3D8);

  /// Cor de fundo dos ecrãs.
  static const Color background = Color(0xFFF6F8FA);

  /// Verde para valores positivos / sucesso.
  static const Color success = Color(0xFF15803D);

  /// Vermelho para valores negativos / erros.
  static const Color error = Color(0xFFB42318);

  /// Laranja para estados de aviso ou pendente.
  static const Color warning = Color(0xFFF59E0B);
}
