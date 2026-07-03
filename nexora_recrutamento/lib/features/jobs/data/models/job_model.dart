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
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as int,
      title: json['titulo'] as String? ?? json['title'] as String? ?? '',
      company: json['empresa'] as String? ?? json['company'] as String? ?? '',
      location: json['localizacao'] as String? ?? json['location'] as String? ?? '',
      type: json['tipo'] as String? ?? 'Full-time',
      category: json['categoria'] as String? ?? json['category'] as String? ?? '',
      description: json['descricao'] as String? ?? json['description'] as String? ?? '',
      salary: json['salario'] as String? ?? json['salary'] as String?,
      logoUrl: json['logo_url'] as String? ?? '',
      postedAt: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : DateTime.now(),
      isSaved: json['guardado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': title,
        'empresa': company,
        'localizacao': location,
        'tipo': type,
        'categoria': category,
        'descricao': description,
        'salario': salary,
        'logo_url': logoUrl,
        'criado_em': postedAt.toIso8601String(),
      };
}
