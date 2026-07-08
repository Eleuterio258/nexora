import '../../../../core/errors/exceptions.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';

abstract interface class StudentPortalRemoteDatasource {
  Future<Map<String, dynamic>> me();

  Future<Map<String, dynamic>> dashboard();

  Future<void> logout();

  Future<void> definirSenha({
    required String token,
    required String password,
  });

  Future<void> alterarSenha({
    required String senhaActual,
    required String novaSenha,
  });

  Future<Map<String, dynamic>> boletim({int? termId, int? yearId});

  Future<List<dynamic>> notas({int? termId, int? subjectId});

  Future<Map<String, dynamic>> presencas({
    int page = 1,
    int limit = 30,
    String? mes,
  });

  Future<List<dynamic>> horario();

  Future<List<dynamic>> cobrancas({String? status});

  Future<Map<String, dynamic>> reciboCobranca(String id);

  Future<Map<String, dynamic>> iniciarPagamento({
    required String cobrancaId,
    required String msisdn,
    String provider = 'mpesa',
  });

  Future<Map<String, dynamic>> estadoPagamento({
    required String cobrancaId,
    required String gatewayTransactionId,
  });

  Future<List<dynamic>> mensagens();

  Future<List<dynamic>> eventos();

  Future<Map<String, dynamic>> turma();

  Future<Map<String, dynamic>> noticias({int page = 1, int limit = 20});

  Future<Map<String, dynamic>> ocorrencias();

  Future<Map<String, dynamic>> biblioteca({
    int page = 1,
    int limit = 20,
    String? status,
  });

  Future<void> justificarFalta(String id, {required String motivo});

  Future<void> atualizarPerfil({
    String? telefone,
    String? email,
    String? endereco,
  });
}

class StudentPortalRemoteDatasourceImpl implements StudentPortalRemoteDatasource {
  const StudentPortalRemoteDatasourceImpl(this._client);

  final RestClient _client;

  @override
  Future<Map<String, dynamic>> me() => _getMap('/api/portal/aluno/me');

  @override
  Future<Map<String, dynamic>> dashboard() => _getMap('/api/portal/aluno/me/dashboard');

  @override
  Future<void> logout() async {
    await _request(() => _client.auth().post('/api/portal/aluno/logout'));
  }

  @override
  Future<void> definirSenha({
    required String token,
    required String password,
  }) async {
    await _request(
      () => _client.unauth().post(
        '/api/portal/aluno/definir-senha',
        data: {'token': token, 'password': password},
      ),
    );
  }

  @override
  Future<void> alterarSenha({
    required String senhaActual,
    required String novaSenha,
  }) async {
    await _request(
      () => _client.auth().post(
        '/api/portal/aluno/alterar-senha',
        data: {'senha_actual': senhaActual, 'nova_senha': novaSenha},
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> boletim({int? termId, int? yearId}) {
    return _getMap(
      '/api/portal/aluno/me/boletim',
      queryParameters: _clean({'term_id': termId, 'year_id': yearId}),
    );
  }

  @override
  Future<List<dynamic>> notas({int? termId, int? subjectId}) {
    return _getList(
      '/api/portal/aluno/me/notas',
      queryParameters: _clean({'term_id': termId, 'subject_id': subjectId}),
    );
  }

  @override
  Future<Map<String, dynamic>> presencas({
    int page = 1,
    int limit = 30,
    String? mes,
  }) {
    return _getMap(
      '/api/portal/aluno/me/presencas',
      queryParameters: _clean({'page': page, 'limit': limit, 'mes': mes}),
    );
  }

  @override
  Future<List<dynamic>> horario() => _getList('/api/portal/aluno/me/horario');

  @override
  Future<List<dynamic>> cobrancas({String? status}) {
    return _getList(
      '/api/portal/aluno/me/cobrancas',
      queryParameters: _clean({'status': status}),
    );
  }

  @override
  Future<Map<String, dynamic>> reciboCobranca(String id) {
    return _getMap('/api/portal/aluno/me/cobrancas/$id/recibo');
  }

  @override
  Future<Map<String, dynamic>> iniciarPagamento({
    required String cobrancaId,
    required String msisdn,
    String provider = 'mpesa',
  }) {
    return _postMap(
      '/api/portal/aluno/me/cobrancas/$cobrancaId/pagar',
      data: {'msisdn': msisdn, 'provider': provider},
    );
  }

  @override
  Future<Map<String, dynamic>> estadoPagamento({
    required String cobrancaId,
    required String gatewayTransactionId,
  }) {
    return _getMap(
      '/api/portal/aluno/me/cobrancas/$cobrancaId/pagamento/$gatewayTransactionId',
    );
  }

  @override
  Future<List<dynamic>> mensagens() =>
      _getList('/api/portal/aluno/me/mensagens');

  @override
  Future<List<dynamic>> eventos() =>
      _getList('/api/portal/aluno/me/eventos');

  @override
  Future<Map<String, dynamic>> turma() =>
      _getMap('/api/portal/aluno/me/turma');

  @override
  Future<Map<String, dynamic>> noticias({int page = 1, int limit = 20}) {
    return _getMap(
      '/api/portal/aluno/me/noticias',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<Map<String, dynamic>> ocorrencias() =>
      _getMap('/api/portal/aluno/me/ocorrencias');

  @override
  Future<void> justificarFalta(String id, {required String motivo}) async {
    await _request(
      () => _client.auth().post(
        '/api/portal/aluno/me/presencas/$id/justificar',
        data: {'motivo': motivo},
      ),
    );
  }

  @override
  Future<void> atualizarPerfil({
    String? telefone,
    String? email,
    String? endereco,
  }) async {
    await _request(
      () => _client.auth().put<void>(
        '/api/portal/aluno/me',
        data: _clean({
          'telefone': telefone,
          'email': email,
          'endereco': endereco,
        }),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> biblioteca({
    int page = 1,
    int limit = 20,
    String? status,
  }) {
    return _getMap(
      '/api/portal/aluno/me/biblioteca',
      queryParameters: _clean({'page': page, 'limit': limit, 'status': status}),
    );
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _request(
      () => _client.auth().get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> _postMap(String path, {Object? data}) async {
    final response = await _request(
      () => _client.auth().post<Map<String, dynamic>>(path, data: data),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _request(
      () => _client.auth().get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      ),
    );
    return List<dynamic>.from(response.data as List);
  }

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on RestClientException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw const UnauthorizedException();
      }
      if (e.statusCode == 400 || e.statusCode == 422) {
        throw const InvalidInputException();
      }
      if (e.statusCode == null) {
        throw const NetworkException();
      }
      throw const ServerException();
    }
  }

  Map<String, dynamic> _clean(Map<String, dynamic> query) {
    return Map.fromEntries(
      query.entries.where((entry) => entry.value != null && entry.value != ''),
    );
  }
}
