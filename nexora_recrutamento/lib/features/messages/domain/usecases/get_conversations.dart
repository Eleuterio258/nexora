import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/messages_repository.dart';

class GetConversations extends UseCase<List<Conversation>, NoParams> {
  final MessagesRepository repository;
  const GetConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(NoParams params) =>
      repository.getConversations();
}
