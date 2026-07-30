import 'package:equatable/equatable.dart';

import '../../domain/entities/conversa_entity.dart';
import '../../domain/entities/mensagem_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ConversasLoaded extends ChatState {
  final List<ConversaEntity> conversas;

  const ConversasLoaded({required this.conversas});

  @override
  List<Object?> get props => [conversas];
}

class MensagensLoaded extends ChatState {
  final List<MensagemEntity> mensagens;

  const MensagensLoaded({required this.mensagens});

  @override
  List<Object?> get props => [mensagens];
}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
