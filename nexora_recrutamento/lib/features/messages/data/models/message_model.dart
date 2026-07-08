import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.candidaturaId,
    required super.author,
    required super.content,
    required super.createdAt,
    required super.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'] as String? ?? '';
    return MessageModel(
      id: json['id'] as int,
      candidaturaId: json['candidatura_id'] as int,
      author: autor,
      content: json['conteudo'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      // O backend marca as mensagens do próprio candidato com autor='candidato'
      // (ver autorCandidato em candidato_mensagens.go); qualquer outro autor
      // (recrutador, 'sistema', 'admin') é tratado como do lado do recrutador.
      sender: autor == 'candidato' ? MessageSender.candidato : MessageSender.recrutador,
    );
  }
}
