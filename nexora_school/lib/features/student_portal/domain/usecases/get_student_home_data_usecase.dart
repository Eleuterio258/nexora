import '../entities/student_home_data.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentHomeDataUseCase {
  const GetStudentHomeDataUseCase(this._repository);

  final StudentPortalRepository _repository;

  Future<StudentHomeData> call() => _repository.getHomeData();
}
