import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversas extends ChatEvent {
  const LoadConversas();
}

class LoadMensagens extends ChatEvent {
  final int conversaId;

  const LoadMensagens({required this.conversaId});

  @override
  List<Object?> get props => [conversaId];
}

class EnviarMensagem extends ChatEvent {
  final int conversaId;
  final String conteudo;

  const EnviarMensagem({required this.conversaId, required this.conteudo});

  @override
  List<Object?> get props => [conversaId, conteudo];
}
