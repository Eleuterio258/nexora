import '../entities/student_mensagem.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentMensagensUseCase {
  const GetStudentMensagensUseCase(this._repository);

  final StudentPortalRepository _repository;

  Future<List<StudentMensagem>> call() => _repository.getMensagens();
}
