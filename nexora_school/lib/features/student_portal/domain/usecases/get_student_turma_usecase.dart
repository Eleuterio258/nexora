import '../entities/student_turma_data.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentTurmaUseCase {
  const GetStudentTurmaUseCase(this._repository);
  final StudentPortalRepository _repository;
  Future<StudentTurmaData> call() => _repository.getTurma();
}
