import 'package:flutter/material.dart';

extension HexColor on String {
  /// Converte uma string hexadecimal (#RRGGBB ou #AARRGGBB) em [Color].
  /// Retorna [fallback] se o formato for inválido.
  Color toColor({Color fallback = const Color(0xFF10B981)}) {
    var value = trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;

    final parsed = int.tryParse('0x$value');
    return parsed != null ? Color(parsed) : fallback;
  }
}

extension ColorHex on Color {
  /// Devolve a cor no formato #RRGGBB.
  String toHex() {
    final argb = toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${argb.substring(2)}';
  }
}