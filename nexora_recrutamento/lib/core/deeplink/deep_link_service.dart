import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/jobs/domain/usecases/get_job_by_id.dart';
import '../../screens/job_details_screen.dart';
import '../navigation/app_navigator.dart';

/// Trata os deep links partilhados a partir do ecrã de detalhe de uma vaga
/// (ver job_details_screen.dart), no formato `nexoraapp://vaga/<id>`.
/// Ao abrir o link — com a app fechada, em background, ou já aberta — a app
/// vai directamente ao detalhe dessa vaga.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final GetJobById getJobById;
  StreamSubscription<Uri>? _sub;

  DeepLinkService({required this.getJobById});

  Future<void> start() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {
      // Sem link inicial ou plataforma sem suporte — ignora.
    }
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'nexoraapp' || uri.host != 'vaga') return;
    final idStr = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    final id = idStr != null ? int.tryParse(idStr) : null;
    if (id == null) return;

    final result = await getJobById(GetJobByIdParams(id));
    result.fold(
      (_) => null,
      (job) {
        final navigator = appNavigatorKey.currentState;
        if (navigator == null) return;
        navigator.push(
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        );
      },
    );
  }
}
