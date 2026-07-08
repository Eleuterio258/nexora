import '../entities/student_evento.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentEventosUseCase {
  const GetStudentEventosUseCase(this._repository);
  final StudentPortalRepository _repository;
  Future<List<StudentEvento>> call() => _repository.getEventos();
}
