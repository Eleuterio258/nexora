import '../entities/student_presencas_data.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentPresencasUseCase {
  const GetStudentPresencasUseCase(this._repository);

  final StudentPortalRepository _repository;

  Future<StudentPresencasData> call({
    int page = 1,
    int limit = 30,
    String? mes,
  }) => _repository.getPresencas(page: page, limit: limit, mes: mes);
}
