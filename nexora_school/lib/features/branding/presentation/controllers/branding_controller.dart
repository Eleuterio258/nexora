import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:nexora_school/core/constants/app_colors.dart';
import 'package:nexora_school/core/extensions/color_extensions.dart';
import 'package:nexora_school/core/local/local_storage/i_local_storage.dart';
import 'package:nexora_school/core/local/storage_keys.dart';
import '../../data/datasources/branding_remote_datasource.dart';
import '../../data/models/branding_model.dart';
import '../../domain/entities/branding_entity.dart';

class BrandingController {
  BrandingController(this._datasource, this._storage);

  final BrandingRemoteDatasource _datasource;
  final ILocalStorage _storage;

  BrandingEntity _current = const BrandingEntity();

  BrandingEntity get current => _current;

  /// Aplica o branding aos [AppColors] sem tocar na rede.
  void applyBranding(BrandingEntity branding) {
    _current = branding;

    final primary = (branding.primaryColor ?? '#10B981').toColor(
      fallback: AppColorsTheme.defaultTheme.primary,
    );
    final onPrimary = (branding.onPrimaryColor ?? '#FFFFFF').toColor(
      fallback: AppColorsTheme.defaultTheme.onPrimary,
    );

    final defaultTheme = AppColorsTheme.defaultTheme;
    AppColors.update(
      defaultTheme.copyWith(
        primary: primary,
        onPrimary: onPrimary,
        primaryDark: _darken(primary, 0.15),
        primaryLight: _lighten(primary, 0.72),
        mintContainer: _lighten(primary, 0.78),
      ),
    );
  }

  /// Carrega o branding a partir do cache local e aplica as cores.
  Future<void> loadFromCache() async {
    try {
      final jsonString = await _storage.read<String>(StorageKeys.branding);
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        applyBranding(BrandingModel.fromJson(data));
      }
    } catch (_) {
      // Silencia falhas de cache; mantém o tema por omissão.
    }
  }

  /// Busca o branding remoto, guarda em cache local e aplica as cores.
  /// Devolve `true` se conseguiu actualizar, `false` caso contrário.
  Future<bool> refresh() async {
    try {
      final branding = await _datasource.fetchBranding();
      await _cache(branding);
      applyBranding(branding);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Força um refresh silencioso: tenta a rede, mas em caso de falha recai
  /// para o cache local.
  Future<void> refreshOrCache() async {
    final ok = await refresh();
    if (!ok) await loadFromCache();
  }

  Future<void> _cache(BrandingModel branding) async {
    try {
      await _storage.write(
        StorageKeys.branding,
        jsonEncode(branding.toJson()),
      );
    } catch (_) {
      // Ignora falhas de escrita no cache.
    }
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}