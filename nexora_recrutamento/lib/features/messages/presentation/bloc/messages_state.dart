import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation.dart';

abstract class MessagesState extends Equatable {
  const MessagesState();
}

class MessagesInitial extends MessagesState {
  const MessagesInitial();
  @override
  List<Object?> get props => [];
}

class MessagesLoading extends MessagesState {
  const MessagesLoading();
  @override
  List<Object?> get props => [];
}

class ConversationsLoaded extends MessagesState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class MessagesFailureState extends MessagesState {
  final String message;
  const MessagesFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
