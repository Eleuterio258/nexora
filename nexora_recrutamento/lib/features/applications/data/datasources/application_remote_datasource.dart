import '../../../../core/network/api_client.dart';
import '../models/application_model.dart';

abstract class ApplicationRemoteDataSource {
  Future<List<ApplicationModel>> getApplications(String token);
  Future<ApplicationModel> getApplicationById(int id, String token);
  Future<ApplicationModel> submitApplication({
    required int jobId,
    required String coverLetter,
    required String token,
  });
}

class ApplicationRemoteDataSourceImpl implements ApplicationRemoteDataSource {
  final ApiClient client;
  const ApplicationRemoteDataSourceImpl(this.client);

  @override
  Future<List<ApplicationModel>> getApplications(String token) async {
    final list = await client.getList('/api/recrutamento/candidaturas');
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ApplicationModel> getApplicationById(int id, String token) async {
    final json = await client.get('/api/recrutamento/candidaturas/$id');
    return ApplicationModel.fromJson(json);
  }

  @override
  Future<ApplicationModel> submitApplication({
    required int jobId,
    required String coverLetter,
    required String token,
  }) async {
    final json = await client.post('/api/recrutamento/candidaturas', {
      'vaga_id': jobId,
      'carta_apresentacao': coverLetter,
    });
    return ApplicationModel.fromJson(json);
  }
}
