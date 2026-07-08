import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';

class SendConversationMessage
    extends UseCase<Message, SendConversationMessageParams> {
  final MessagesRepository repository;
  const SendConversationMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(
    SendConversationMessageParams params,
  ) =>
      repository.sendMessage(
        candidaturaId: params.candidaturaId,
        content: params.content,
      );
}

class SendConversationMessageParams extends Equatable {
  final int candidaturaId;
  final String content;
  const SendConversationMessageParams({
    required this.candidaturaId,
    required this.content,
  });

  @override
  List<Object?> get props => [candidaturaId, content];
}
