import '../../domain/entities/student_boletim_data.dart';
import '../../domain/entities/student_financeiro_data.dart';
import '../../domain/entities/student_home_data.dart';
import '../../domain/entities/student_presencas_data.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../datasources/student_portal_remote_datasource.dart';

class StudentPortalRepositoryImpl implements StudentPortalRepository {
  const StudentPortalRepositoryImpl(this._datasource);

  final StudentPortalRemoteDatasource _datasource;

  @override
  Future<StudentHomeData> getHomeData() async {
    final results = await Future.wait([
      _datasource.me(),
      _datasource.dashboard(),
      _datasource.mensagens(),
      _datasource.eventos(),
    ]);

    final me = results[0] as Map<String, dynamic>;
    final dashboard = results[1] as Map<String, dynamic>;
    final mensagens = results[2] as List<dynamic>;
    final eventos = results[3] as List<dynamic>;

    final matricula = me['matricula_activa'] as Map<String, dynamic>? ?? {};

    return StudentHomeData(
      nome: (me['nome'] ?? '').toString(),
      email: (me['email'] ?? '').toString(),
      matricula: (matricula['numero'] ?? '').toString(),
      turma: (matricula['turma'] ?? '').toString(),
      anoLectivo: (matricula['ano_lectivo'] ?? '').toString(),
      dataIngresso: matricula['data_inicio']?.toString(),
      aulasHoje: (dashboard['aulas_hoje'] ?? 0) as int,
      mediaGeral: _toDouble(dashboard['media_geral']),
      faltas: (dashboard['faltas'] ?? 0) as int,
      faltasPermitidas: (dashboard['faltas_permitidas'] ?? 0) as int,
      mensagens: mensagens,
      eventos: eventos,
    );
  }

  @override
  Future<StudentBoletimData> getBoletim({int? termId}) async {
    final boletim = await _datasource.boletim(termId: termId);
    return StudentBoletimData(
      terms: (boletim['terms'] as List<dynamic>? ?? []),
      grades: (boletim['grades'] as List<dynamic>? ?? []),
      media: _toDouble(boletim['media']),
    );
  }

  @override
  Future<StudentFinanceiroData> getCobrancas({String? status}) async {
    final cobrancas = await _datasource.cobrancas(status: status);
    return StudentFinanceiroData(cobrancas: cobrancas);
  }

  @override
  Future<StudentPresencasData> getPresencas({
    int page = 1,
    int limit = 30,
    String? mes,
  }) async {
    final presencas = await _datasource.presencas(
      page: page,
      limit: limit,
      mes: mes,
    );
    return StudentPresencasData(
      records: (presencas['records'] as List<dynamic>? ?? []),
      pagina: (presencas['pagina'] ?? 1) as int,
      paginas: (presencas['paginas'] ?? 1) as int,
      porPagina: (presencas['por_pagina'] ?? limit) as int,
      total: (presencas['total'] ?? 0) as int,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
