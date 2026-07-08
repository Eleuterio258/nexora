import '../repositories/student_portal_repository.dart';

class GetStudentBibliotecaUseCase {
  const GetStudentBibliotecaUseCase(this._repository);
  final StudentPortalRepository _repository;
  Future<Map<String, dynamic>> call({int page = 1, int limit = 20}) =>
      _repository.getBiblioteca(page: page, limit: limit);
}
