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

  static const _subjectColors = {
    'matematica': Color(0xFF10B981),
    'lingua portuguesa': Color(0xFF3B82F6),
    'ingles': Color(0xFF8B5CF6),
    'fisica': Color(0xFFF59E0B),
    'biologia': Color(0xFF06B6D4),
    'quimica': Color(0xFFEC4899),
    'historia': Color(0xFFEF4444),
    'ed. fisica': Color(0xFF14B8A6),
    'geografia': Color(0xFF6366F1),
    'redacao': Color(0xFFF97316),
    'informatica': Color(0xFF0EA5E9),
    'desenho': Color(0xFF14B8A6),
    'introducao ao planeamento': Color(0xFF06B6D4),
  };

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
      icon: Icons.school_outlined,
      color: _color(disciplina),
      weekday: (e['dia_semana'] ?? 1) as int,
    );
  }

  static Color _color(String subject) {
    final key = subject.toLowerCase();
    for (final entry in _subjectColors.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return const Color(0xFF64748B);
  }
}
