class EducationModel {
  final int id;
  final int candidatoId;
  final String curso;
  final String instituicao;
  final String? local;
  final int? anoInicio;
  final int? anoFim;
  final String? nota;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EducationModel({
    required this.id,
    required this.candidatoId,
    required this.curso,
    required this.instituicao,
    this.local,
    this.anoInicio,
    this.anoFim,
    this.nota,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id'] as int,
      candidatoId: json['candidato_id'] as int,
      curso: json['curso'] as String,
      instituicao: json['instituicao'] as String,
      local: json['local'] as String?,
      anoInicio: json['ano_inicio'] as int?,
      anoFim: json['ano_fim'] as int?,
      nota: json['nota'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curso': curso,
      'instituicao': instituicao,
      if (local != null) 'local': local,
      if (anoInicio != null) 'ano_inicio': anoInicio,
      if (anoFim != null) 'ano_fim': anoFim,
      if (nota != null) 'nota': nota,
    };
  }

  EducationModel copyWith({
    int? id,
    int? candidatoId,
    String? curso,
    String? instituicao,
    String? local,
    int? anoInicio,
    int? anoFim,
    String? nota,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationModel(
      id: id ?? this.id,
      candidatoId: candidatoId ?? this.candidatoId,
      curso: curso ?? this.curso,
      instituicao: instituicao ?? this.instituicao,
      local: local ?? this.local,
      anoInicio: anoInicio ?? this.anoInicio,
      anoFim: anoFim ?? this.anoFim,
      nota: nota ?? this.nota,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
