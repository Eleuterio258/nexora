import '../entities/student_boletim_data.dart';
import '../entities/student_evento.dart';
import '../entities/student_financeiro_data.dart';
import '../entities/student_home_data.dart';
import '../entities/student_mensagem.dart';
import '../entities/student_noticia.dart';
import '../entities/student_presencas_data.dart';
import '../entities/student_turma_data.dart';

abstract interface class StudentPortalRepository {
  Future<StudentHomeData> getHomeData();
  Future<StudentBoletimData> getBoletim({int? termId, int? yearId});
  Future<StudentFinanceiroData> getCobrancas({String? status});
  Future<StudentPresencasData> getPresencas({
    int page = 1,
    int limit = 30,
    String? mes,
  });
  Future<List<StudentMensagem>> getMensagens();
  Future<StudentTurmaData> getTurma();
  Future<StudentNoticiasData> getNoticias({int page = 1, int limit = 20});
  Future<List<StudentEvento>> getEventos();
  Future<Map<String, dynamic>> getOcorrencias();
  Future<Map<String, dynamic>> getBiblioteca({int page = 1, int limit = 20});
  Future<void> justificarFalta(String id, {required String motivo});
  Future<void> atualizarPerfil({
    String? telefone,
    String? email,
    String? endereco,
  });
}
