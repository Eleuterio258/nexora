import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final int candidaturaId;
  final String jobTitle;
  final String estado;
  final String? lastAuthor;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.candidaturaId,
    required this.jobTitle,
    required this.estado,
    this.lastAuthor,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [candidaturaId];
}
