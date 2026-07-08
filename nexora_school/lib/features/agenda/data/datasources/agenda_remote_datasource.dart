import 'package:flutter/material.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../../domain/entities/aula_entity.dart';

abstract interface class AgendaRemoteDatasource {
  Future<List<AulaEntity>> getHorario();
}

class AgendaRemoteDatasourceImpl implements AgendaRemoteDatasource {
  AgendaRemoteDatasourceImpl(this._client);

  final RestClient _client;
  List<AulaEntity>? _cache;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);


  @override
  Future<List<AulaEntity>> getHorario() async {
    final now = DateTime.now();
    if (_cache != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cache!;
    }

    try {
      final response = await _client.auth().get<List<dynamic>>(
        '/api/portal/aluno/me/horario',
      );
      final list = response.data ?? [];
      _cache = list.map((e) => _map(e as Map<String, dynamic>)).toList();
      _cachedAt = now;
      return _cache!;
    } on RestClientException catch (e) {
      if (e.statusCode == 401) throw const UnauthorizedException();
      if (e.statusCode == null) throw const NetworkException();
      throw const ServerException();
    }
  }

  AulaEntity _map(Map<String, dynamic> e) {
    final disciplina = (e['disciplina'] ?? '').toString();
    final professor = (e['professor'] ?? '').toString();
    final sala = (e['sala'] ?? '').toString();
    final slot = e['slot'] as Map<String, dynamic>? ?? {};
    final horaInicio = (slot['hora_inicio'] ?? '').toString();
    final horaFim = (slot['hora_fim'] ?? '').toString();
    final time = horaInicio.isNotEmpty && horaFim.isNotEmpty
        ? '${horaInicio.substring(0, 5)}–${horaFim.substring(0, 5)}'
        : '';

    return AulaEntity(
      subject: disciplina,
      teacher: professor.isNotEmpty ? professor : sala,
      activity: sala.isNotEmpty ? 'Sala: $sala' : '',
      time: time,
      icon: _resolveIcon(e['icone'] as String?),
      color: _resolveColor(e['cor'] as String?),
      weekday: (e['dia_semana'] ?? 1) as int,
    );
  }

  static const _icons = {
    'calculate':      Icons.calculate_outlined,
    'science':        Icons.science_outlined,
    'history_edu':    Icons.history_edu_outlined,
    'sports_soccer':  Icons.sports_soccer_outlined,
    'music_note':     Icons.music_note_outlined,
    'brush':          Icons.brush_outlined,
    'computer':       Icons.computer_outlined,
    'language':       Icons.language_outlined,
    'biotech':        Icons.biotech_outlined,
    'public':         Icons.public_outlined,
    'menu_book':      Icons.menu_book_outlined,
    'functions':      Icons.functions_outlined,
    'psychology':     Icons.psychology_outlined,
    'architecture':   Icons.architecture_outlined,
  };

  static IconData _resolveIcon(String? apiIcon) =>
      _icons[apiIcon] ?? Icons.school_outlined;

  static Color _resolveColor(String? apiColor) {
    if (apiColor != null && apiColor.length == 7 && apiColor.startsWith('#')) {
      final hex = int.tryParse('0xFF${apiColor.substring(1)}');
      if (hex != null) return Color(hex);
    }
    return const Color(0xFF64748B);
  }
}
