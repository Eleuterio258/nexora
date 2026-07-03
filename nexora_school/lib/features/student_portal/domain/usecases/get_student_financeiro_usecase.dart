import '../entities/student_financeiro_data.dart';
import '../repositories/student_portal_repository.dart';

class GetStudentFinanceiroUseCase {
  const GetStudentFinanceiroUseCase(this._repository);

  final StudentPortalRepository _repository;

  Future<StudentFinanceiroData> call({String? status}) =>
      _repository.getCobrancas(status: status);
}
