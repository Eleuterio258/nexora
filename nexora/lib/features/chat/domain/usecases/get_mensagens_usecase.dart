import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mensagem_entity.dart';
import '../repositories/chat_repository.dart';

class GetMensagensUseCase implements UseCase<List<MensagemEntity>, int> {
  final ChatRepository repository;

  GetMensagensUseCase(this.repository);

  @override
  Future<Either<Failure, List<MensagemEntity>>> call(int conversaId) {
    return repository.getMensagens(conversaId);
  }
}
