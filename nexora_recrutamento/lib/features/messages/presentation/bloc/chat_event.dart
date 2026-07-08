import 'package:equatable/equatable.dart';

import '../../domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
}

class ChatMessagesLoadRequested extends ChatEvent {
  final int candidaturaId;
  const ChatMessagesLoadRequested(this.candidaturaId);
  @override
  List<Object?> get props => [candidaturaId];
}

class ChatMessageSendRequested extends ChatEvent {
  final int candidaturaId;
  final String content;
  const ChatMessageSendRequested({
    required this.candidaturaId,
    required this.content,
  });
  @override
  List<Object?> get props => [candidaturaId, content];
}

class ChatMessageReceived extends ChatEvent {
  final Message message;
  const ChatMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}
