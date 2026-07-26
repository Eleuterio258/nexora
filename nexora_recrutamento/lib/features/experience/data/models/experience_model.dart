class ExperienceModel {
  final int id;
  final int candidatoId;
  final String cargo;
  final String empresa;
  final String? local;
  final String dataInicio;
  final String? dataFim;
  final bool actual;
  final String? descricao;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExperienceModel({
    required this.id,
    required this.candidatoId,
    required this.cargo,
    required this.empresa,
    this.local,
    required this.dataInicio,
    this.dataFim,
    required this.actual,
    this.descricao,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] as int,
      candidatoId: json['candidato_id'] as int,
      cargo: json['cargo'] as String,
      empresa: json['empresa'] as String,
      local: json['local'] as String?,
      dataInicio: json['data_inicio'] as String,
      dataFim: json['data_fim'] as String?,
      actual: json['actual'] as bool? ?? false,
      descricao: json['descricao'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo': cargo,
      'empresa': empresa,
      if (local != null) 'local': local,
      'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
      'actual': actual,
      if (descricao != null) 'descricao': descricao,
    };
  }

  ExperienceModel copyWith({
    int? id,
    int? candidatoId,
    String? cargo,
    String? empresa,
    String? local,
    String? dataInicio,
    String? dataFim,
    bool? actual,
    String? descricao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExperienceModel(
      id: id ?? this.id,
      candidatoId: candidatoId ?? this.candidatoId,
      cargo: cargo ?? this.cargo,
      empresa: empresa ?? this.empresa,
      local: local ?? this.local,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      actual: actual ?? this.actual,
      descricao: descricao ?? this.descricao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
