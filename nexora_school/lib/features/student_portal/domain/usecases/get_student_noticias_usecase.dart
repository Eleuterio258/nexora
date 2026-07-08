import '../entities/student_noticia.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentNoticiasUseCase {
  const GetStudentNoticiasUseCase(this._repository);
  final StudentPortalRepository _repository;
  Future<StudentNoticiasData> call({int page = 1, int limit = 20}) =>
      _repository.getNoticias(page: page, limit: limit);
}
