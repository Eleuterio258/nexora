import '../../domain/entities/job.dart';

class JobModel extends Job {
  const JobModel({
    required super.id,
    required super.title,
    required super.company,
    required super.location,
    required super.type,
    required super.category,
    required super.description,
    super.salary,
    required super.logoUrl,
    required super.postedAt,
    super.isSaved,
    super.about,
    super.responsibilities,
    super.requiredQualifications,
    super.preferredQualifications,
    super.benefits,
    super.numberOfPositions,
    super.deadline,
  });

  /// Mapeia o objecto "vaga" tal como devolvido pelo backend Go
  /// (GET /api/public/recrutamento/vagas e /vagas/{id}) — sem conceito de
  /// "empresa" ou "logo" porque é um portal de uma única entidade empregadora.
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as int,
      title: json['titulo'] as String? ?? '',
      company: json['empresa'] as String? ?? 'E258Tech',
      location: json['local'] as String? ?? '',
      type: json['tipo'] as String? ?? 'Estágio',
      category: json['area'] as String? ?? '',
      description: json['descricao'] as String? ?? '',
      salary: json['salario'] as String?,
      logoUrl: json['logo_url'] as String? ?? '',
      postedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isSaved: json['guardado'] as bool? ?? false,
      about: json['sobre_funcao'] as String?,
      responsibilities: _stringList(json['responsabilidades']),
      requiredQualifications: _stringList(json['req_obrigatorios']),
      preferredQualifications: _stringList(json['req_preferenciais']),
      benefits: _stringList(json['oferece']),
      numberOfPositions: json['num_vagas'] as int? ?? 1,
      deadline: json['prazo'] != null && (json['prazo'] as String).isNotEmpty
          ? DateTime.tryParse(json['prazo'] as String)
          : null,
    );
  }

  static List<String> _stringList(dynamic value) =>
      (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': title,
        'local': location,
        'tipo': type,
        'area': category,
        'descricao': description,
        'sobre_funcao': about,
        'responsabilidades': responsibilities,
        'req_obrigatorios': requiredQualifications,
        'req_preferenciais': preferredQualifications,
        'oferece': benefits,
        'num_vagas': numberOfPositions,
        'created_at': postedAt.toIso8601String(),
      };
}
