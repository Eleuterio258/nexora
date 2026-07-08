import 'package:dio/dio.dart';
import 'package:nexora_recrutamento/core/error/rest_exception_mapper.dart';
import 'package:nexora_recrutamento/core/rest_client/rest_client.dart';
import 'package:nexora_recrutamento/core/rest_client/rest_client_exception.dart';

import '../models/application_model.dart';

abstract class ApplicationRemoteDataSource {
  Future<List<ApplicationModel>> getApplications();
  Future<ApplicationModel> getApplicationById(int id);
  Future<ApplicationModel> submitApplication({
    required int jobId,
    required String jobTitle,
    required String nome,
    required String email,
    String? telefone,
    required String coverLetter,
  });
}

class ApplicationRemoteDataSourceImpl implements ApplicationRemoteDataSource {
  final RestClient client;
  const ApplicationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ApplicationModel>> getApplications() async {
    try {
      // Requer sessão de candidato (RequireCandidatoAuth no backend) — .auth().
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/candidaturas',
      );
      final list = res.data ?? [];
      return list
          .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<ApplicationModel> getApplicationById(int id) async {
    // Não existe endpoint de candidatura única para o candidato — filtra na
    // lista, que já traz todos os campos necessários ao ecrã de detalhe.
    final all = await getApplications();
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => throw StateError('Candidatura $id não encontrada.'),
    );
  }

  @override
  Future<ApplicationModel> submitApplication({
    required int jobId,
    required String jobTitle,
    required String nome,
    required String email,
    String? telefone,
    required String coverLetter,
  }) async {
    // POST multipart/form-data — o backend faz r.ParseMultipartForm() e lê
    // os campos com r.FormValue(...), por isso não pode ir como JSON.
    // tipo_candidatura=conta porque o candidato já está autenticado.
    try {
      await client.auth().post(
        '/api/public/recrutamento/candidaturas',
        data: FormData.fromMap({
          'vaga_id': jobId.toString(),
          'vaga_titulo': jobTitle,
          'nome': nome,
          'email': email,
          if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
          'carta': coverLetter,
          'tipo_candidatura': 'conta',
        }),
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }

    // A submissão não devolve a candidatura completa — vai buscá-la à lista.
    final all = await getApplications();
    return all.firstWhere((a) => a.jobId == jobId, orElse: () => all.first);
  }
}
