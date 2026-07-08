class StudentEvento {
  final String id;
  final String titulo;
  final String? descricao;
  final String dataInicio;
  final String? dataFim;
  final bool diaInteiro;
  final String? tipo;
  final String? cor;

  const StudentEvento({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.diaInteiro = false,
    this.tipo,
    this.cor,
  });

  factory StudentEvento.fromJson(Map<String, dynamic> j) => StudentEvento(
        id: j['id']?.toString() ?? '',
        titulo: (j['titulo'] ?? '').toString(),
        descricao: j['descricao']?.toString(),
        dataInicio: (j['data_inicio'] ?? '').toString(),
        dataFim: j['data_fim']?.toString(),
        diaInteiro: j['dia_inteiro'] as bool? ?? false,
        tipo: j['tipo']?.toString(),
        cor: j['cor']?.toString(),
      );
}
