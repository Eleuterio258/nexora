class StudentNoticia {
  final String id;
  final String titulo;
  final String tipo;
  final String? publicadoEm;

  const StudentNoticia({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.publicadoEm,
  });

  factory StudentNoticia.fromJson(Map<String, dynamic> j) => StudentNoticia(
        id: j['id']?.toString() ?? '',
        titulo: (j['titulo'] ?? '').toString(),
        tipo: (j['tipo'] ?? '').toString(),
        publicadoEm: j['publicado_em']?.toString(),
      );
}

class StudentNoticiasData {
  final List<StudentNoticia> noticias;
  final int total;
  final int pagina;
  final int paginas;

  const StudentNoticiasData({
    required this.noticias,
    required this.total,
    required this.pagina,
    required this.paginas,
  });
}
