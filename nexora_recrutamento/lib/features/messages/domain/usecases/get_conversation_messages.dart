import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/messages_repository.dart';

class GetConversationMessages
    extends UseCase<List<Message>, GetConversationMessagesParams> {
  final MessagesRepository repository;
  const GetConversationMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(
    GetConversationMessagesParams params,
  ) =>
      repository.getMessages(params.candidaturaId);
}

class GetConversationMessagesParams extends Equatable {
  final int candidaturaId;
  const GetConversationMessagesParams(this.candidaturaId);

  @override
  List<Object?> get props => [candidaturaId];
}
