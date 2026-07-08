import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
  @override
  List<Object?> get props => [];
}

class ChatLoading extends ChatState {
  const ChatLoading();
  @override
  List<Object?> get props => [];
}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool sending;
  const ChatLoaded(this.messages, {this.sending = false});
  @override
  List<Object?> get props => [messages, sending];
}

class ChatFailureState extends ChatState {
  final String message;
  const ChatFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
