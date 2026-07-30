import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversa_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversasUseCase implements UseCase<List<ConversaEntity>, NoParams> {
  final ChatRepository repository;

  GetConversasUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConversaEntity>>> call(NoParams params) {
    return repository.getConversas();
  }
}
