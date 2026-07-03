import '../../../../core/network/api_client.dart';
import '../models/job_model.dart';

abstract class JobRemoteDataSource {
  Future<List<JobModel>> getJobs({String? category, String? query});
  Future<JobModel> getJobById(int id);
  Future<void> saveJob(int jobId, String token);
  Future<void> unsaveJob(int jobId, String token);
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final ApiClient client;

  const JobRemoteDataSourceImpl(this.client);

  @override
  Future<List<JobModel>> getJobs({String? category, String? query}) async {
    final params = <String>[];
    if (category != null && category.isNotEmpty) params.add('categoria=$category');
    if (query != null && query.isNotEmpty) params.add('q=$query');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';

    final list = await client.getList('/api/recrutamento/vagas$qs');
    return list.map((e) => JobModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<JobModel> getJobById(int id) async {
    final json = await client.get('/api/recrutamento/vagas/$id');
    return JobModel.fromJson(json);
  }

  @override
  Future<void> saveJob(int jobId, String token) =>
      client.post('/api/recrutamento/vagas/$jobId/guardar', {});

  @override
  Future<void> unsaveJob(int jobId, String token) =>
      client.post('/api/recrutamento/vagas/$jobId/remover-guardado', {});
}
