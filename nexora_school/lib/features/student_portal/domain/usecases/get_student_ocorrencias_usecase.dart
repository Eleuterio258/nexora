import '../repositories/student_portal_repository.dart';

class GetStudentOcorrenciasUseCase {
  const GetStudentOcorrenciasUseCase(this._repository);
  final StudentPortalRepository _repository;
  Future<Map<String, dynamic>> call() => _repository.getOcorrencias();
}
