import '../../../../core/error/rest_exception_mapper.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/experience_model.dart';

abstract class ExperienceRemoteDataSource {
  Future<List<ExperienceModel>> getExperiences();
  Future<ExperienceModel> createExperience(ExperienceModel experience);
  Future<void> updateExperience(int id, ExperienceModel experience);
  Future<void> deleteExperience(int id);
}

class ExperienceRemoteDataSourceImpl implements ExperienceRemoteDataSource {
  final RestClient client;

  const ExperienceRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ExperienceModel>> getExperiences() async {
    try {
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/experiencias',
      );
      final list = res.data ?? [];
      return list
          .map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<ExperienceModel> createExperience(ExperienceModel experience) async {
    try {
      final res = await client.auth().post<Map<String, dynamic>>(
        '/api/public/recrutamento/candidatos/experiencias',
        data: experience.toJson(),
      );
      return ExperienceModel.fromJson(res.data ?? {});
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> updateExperience(int id, ExperienceModel experience) async {
    try {
      await client.auth().put<dynamic>(
        '/api/public/recrutamento/candidatos/experiencias/$id',
        data: experience.toJson(),
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> deleteExperience(int id) async {
    try {
      await client.auth().delete<dynamic>(
        '/api/public/recrutamento/candidatos/experiencias/$id',
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
