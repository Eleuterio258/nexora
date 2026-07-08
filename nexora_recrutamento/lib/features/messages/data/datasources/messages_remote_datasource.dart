import '../../../../core/error/rest_exception_mapper.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class MessagesRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(int candidaturaId);
  Future<MessageModel> sendMessage(int candidaturaId, String content);
}

class MessagesRemoteDataSourceImpl implements MessagesRemoteDataSource {
  final RestClient client;
  const MessagesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      // Requer sessão de candidato (RequireCandidatoAuth no backend) — .auth().
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/conversas',
      );
      final list = res.data ?? [];
      return list
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<List<MessageModel>> getMessages(int candidaturaId) async {
    try {
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/candidaturas/$candidaturaId/mensagens',
      );
      final list = res.data ?? [];
      return list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<MessageModel> sendMessage(int candidaturaId, String content) async {
    try {
      final res = await client.auth().post<Map<String, dynamic>>(
        '/api/public/recrutamento/candidatos/candidaturas/$candidaturaId/mensagens',
        data: {'conteudo': content},
      );
      return MessageModel.fromJson(res.data ?? {});
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
