import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class EnviarMensagemUseCase implements UseCase<int, EnviarMensagemParams> {
  final ChatRepository repository;

  EnviarMensagemUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(EnviarMensagemParams params) {
    return repository.enviarMensagem(params);
  }
}
