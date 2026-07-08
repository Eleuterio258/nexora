class StudentMensagem {
  const StudentMensagem({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.tipo,
    required this.audienceType,
    this.publicadoEm,
  });

  final int id;
  final String titulo;
  final String conteudo;
  final String tipo;
  final String audienceType;
  final DateTime? publicadoEm;

  factory StudentMensagem.fromJson(Map<String, dynamic> json) {
    return StudentMensagem(
      id: (json['id'] as num).toInt(),
      titulo: (json['titulo'] as String?) ?? '',
      conteudo: (json['conteudo'] as String?) ?? '',
      tipo: (json['tipo'] as String?) ?? 'comunicado',
      audienceType: (json['audience_type'] as String?) ?? 'todos',
      publicadoEm: json['publicado_em'] != null
          ? DateTime.tryParse(json['publicado_em'].toString())
          : null,
    );
  }
}
