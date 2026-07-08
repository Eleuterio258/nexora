import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.candidaturaId,
    required super.jobTitle,
    required super.estado,
    super.lastAuthor,
    super.lastMessage,
    super.lastMessageAt,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      candidaturaId: json['candidatura_id'] as int,
      jobTitle: json['vaga_titulo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      lastAuthor: json['ultimo_autor'] as String?,
      lastMessage: json['ultima_mensagem'] as String?,
      lastMessageAt: json['ultima_data'] == null
          ? null
          : DateTime.parse(json['ultima_data'] as String),
      unreadCount: json['nao_lidas'] as int? ?? 0,
    );
  }
}
