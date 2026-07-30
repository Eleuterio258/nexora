import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/conversa_entity.dart';
import '../entities/mensagem_entity.dart';

class EnviarMensagemParams extends Equatable {
  final int conversaId;
  final String conteudo;

  const EnviarMensagemParams({required this.conversaId, required this.conteudo});

  @override
  List<Object?> get props => [conversaId, conteudo];
}

abstract class ChatRepository {
  Future<Either<Failure, List<ConversaEntity>>> getConversas();

  Future<Either<Failure, List<MensagemEntity>>> getMensagens(int conversaId);

  Future<Either<Failure, int>> enviarMensagem(EnviarMensagemParams params);
}
