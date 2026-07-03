import '../entities/student_boletim_data.dart';
import '../entities/student_financeiro_data.dart';
import '../entities/student_home_data.dart';
import '../entities/student_presencas_data.dart';

abstract interface class StudentPortalRepository {
  Future<StudentHomeData> getHomeData();
  Future<StudentBoletimData> getBoletim({int? termId});
  Future<StudentFinanceiroData> getCobrancas({String? status});
  Future<StudentPresencasData> getPresencas({
    int page = 1,
    int limit = 30,
    String? mes,
  });
}
