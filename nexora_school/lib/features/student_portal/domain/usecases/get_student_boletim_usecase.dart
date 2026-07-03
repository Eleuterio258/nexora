import '../entities/student_boletim_data.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentBoletimUseCase {
  const GetStudentBoletimUseCase(this._repository);

  final StudentPortalRepository _repository;

  Future<StudentBoletimData> call({int? termId}) => _repository.getBoletim(termId: termId);
}
