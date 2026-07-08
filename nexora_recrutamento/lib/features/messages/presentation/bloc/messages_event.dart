import 'package:equatable/equatable.dart';

abstract class MessagesEvent extends Equatable {
  const MessagesEvent();
}

class ConversationsLoadRequested extends MessagesEvent {
  const ConversationsLoadRequested();
  @override
  List<Object?> get props => [];
}
