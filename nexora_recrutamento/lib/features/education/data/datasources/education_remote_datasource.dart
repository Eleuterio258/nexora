import '../../../../core/error/rest_exception_mapper.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/education_model.dart';

abstract class EducationRemoteDataSource {
  Future<List<EducationModel>> getEducations();
  Future<EducationModel> createEducation(EducationModel education);
  Future<void> updateEducation(int id, EducationModel education);
  Future<void> deleteEducation(int id);
}

class EducationRemoteDataSourceImpl implements EducationRemoteDataSource {
  final RestClient client;

  const EducationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<EducationModel>> getEducations() async {
    try {
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/formacoes',
      );
      final list = res.data ?? [];
      return list
          .map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<EducationModel> createEducation(EducationModel education) async {
    try {
      final res = await client.auth().post<Map<String, dynamic>>(
        '/api/public/recrutamento/candidatos/formacoes',
        data: education.toJson(),
      );
      return EducationModel.fromJson(res.data ?? {});
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> updateEducation(int id, EducationModel education) async {
    try {
      await client.auth().put<dynamic>(
        '/api/public/recrutamento/candidatos/formacoes/$id',
        data: education.toJson(),
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> deleteEducation(int id) async {
    try {
      await client.auth().delete<dynamic>(
        '/api/public/recrutamento/candidatos/formacoes/$id',
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
