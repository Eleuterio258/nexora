import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/conversa_model.dart';
import '../models/mensagem_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversaModel>> getConversas();

  Future<List<MensagemModel>> getMensagens(int conversaId);

  Future<int> enviarMensagem({required int conversaId, required String conteudo});
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final RestClient restClient;

  ChatRemoteDataSourceImpl({required this.restClient});

  @override
  Future<List<ConversaModel>> getConversas() async {
    try {
      final response = await restClient.auth().get<List<dynamic>>(
        '/api/self-service/chat/conversas',
      );

      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ConversaModel.fromJson)
          .toList();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao carregar as conversas.');
    }
  }

  @override
  Future<List<MensagemModel>> getMensagens(int conversaId) async {
    try {
      final response = await restClient.auth().get<List<dynamic>>(
        '/api/self-service/chat/conversas/$conversaId/mensagens',
      );

      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(MensagemModel.fromJson)
          .toList();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao carregar as mensagens.');
    }
  }

  @override
  Future<int> enviarMensagem({
    required int conversaId,
    required String conteudo,
  }) async {
    try {
      final response = await restClient.auth().post<Map<String, dynamic>>(
        '/api/self-service/chat/conversas/$conversaId/mensagens',
        data: {'conteudo': conteudo, 'tipo': 'texto'},
      );

      final data = response.data ?? {};
      return (data['id'] as num).toInt();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao enviar a mensagem.');
    }
  }

  Never _handleError(RestClientException e, String fallback) {
    if (e.isTimeout) {
      throw Exception(
        'O servidor demorou demasiado tempo a responder. Tenta novamente.',
      );
    }

    final data = e.response.data;
    final message = data is Map
        ? (data['detail'] ?? data['error'] ?? data['mensagem'])
        : null;
    throw Exception(message?.toString() ?? fallback);
  }
}
