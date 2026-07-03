class StudentHomeData {
  final String nome;
  final String email;
  final String matricula;
  final String turma;
  final String anoLectivo;
  final String? dataIngresso;
  final int aulasHoje;
  final double mediaGeral;
  final int faltas;
  final int faltasPermitidas;
  final List<dynamic> mensagens;
  final List<dynamic> eventos;

  const StudentHomeData({
    required this.nome,
    required this.email,
    required this.matricula,
    required this.turma,
    required this.anoLectivo,
    this.dataIngresso,
    required this.aulasHoje,
    required this.mediaGeral,
    required this.faltas,
    required this.faltasPermitidas,
    required this.mensagens,
    required this.eventos,
  });
}
