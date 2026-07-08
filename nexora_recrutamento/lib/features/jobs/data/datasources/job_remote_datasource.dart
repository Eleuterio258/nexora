import 'package:nexora_recrutamento/core/error/rest_exception_mapper.dart';
import 'package:nexora_recrutamento/core/rest_client/rest_client.dart';
import 'package:nexora_recrutamento/core/rest_client/rest_client_exception.dart';

import '../models/job_model.dart';

abstract class JobRemoteDataSource {
  Future<List<JobModel>> getJobs({
    String? category,
    String? query,
    int? tenantId,
  });
  Future<JobModel> getJobById(int id);
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final RestClient client;

  const JobRemoteDataSourceImpl(this.client);

  @override
  Future<List<JobModel>> getJobs({
    String? category,
    String? query,
    int? tenantId,
  }) async {
    // GET /api/public/recrutamento/vagas — não suporta filtro por
    // categoria/texto no backend, por isso filtramos aqui do lado do cliente.
    // tenant_id identifica de que empregador (tenant) listar vagas — usa-se
    // o tenant do candidato autenticado, quando conhecido.
    Map<String, dynamic>? body;
    try {
      final res = await client.unauth().get<Map<String, dynamic>>(
        '/api/public/recrutamento/vagas',
        queryParameters: {
          'limit': 100,
          if (tenantId != null) 'tenant_id': tenantId,
        },
      );
      body = res.data;
    } on RestClientException catch (e) {
      mapRestException(e);
    }
    final data = body?['data'] as List<dynamic>? ?? [];
    var jobs = data
        .map((e) => JobModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (category != null && category.isNotEmpty) {
      jobs = jobs
          .where((j) => j.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      jobs = jobs
          .where(
            (j) =>
                j.title.toLowerCase().contains(q) ||
                j.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return jobs;
  }

  @override
  Future<JobModel> getJobById(int id) async {
    try {
      final res = await client.unauth().get<Map<String, dynamic>>(
        '/api/public/recrutamento/vagas/$id',
      );
      final body = res.data ?? {};
      final vaga = body['vaga'] as Map<String, dynamic>? ?? body;
      return JobModel.fromJson(vaga);
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
