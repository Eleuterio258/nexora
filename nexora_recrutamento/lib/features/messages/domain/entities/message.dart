import 'package:equatable/equatable.dart';

enum MessageSender { candidato, recrutador }

class Message extends Equatable {
  final int id;
  final int candidaturaId;
  final String author;
  final String content;
  final DateTime createdAt;
  final MessageSender sender;

  const Message({
    required this.id,
    required this.candidaturaId,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.sender,
  });

  @override
  List<Object?> get props => [id];
}
