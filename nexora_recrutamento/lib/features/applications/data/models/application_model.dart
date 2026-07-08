import '../../domain/entities/application.dart';

class ApplicationModel extends Application {
  const ApplicationModel({
    required super.id,
    required super.jobId,
    required super.jobTitle,
    required super.company,
    required super.jobDescription,
    required super.location,
    required super.appliedAt,
    required super.status,
    required super.logoUrl,
    super.trackingCode,
    super.interviewDate,
    super.interviewLocation,
    super.interviewLink,
  });

  /// Mapeia a resposta de GET /api/public/recrutamento/candidatos/candidaturas
  /// — estrutura plana, sem "empresa"/"localizacao"/"logo" (portal de um único
  /// empregador), mas com dados reais de entrevista e código de acompanhamento.
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as int,
      jobId: json['vaga_id'] as int? ?? 0,
      jobTitle: json['vaga_titulo'] as String? ?? '',
      company: 'E258Tech',
      jobDescription: json['vaga_descricao'] as String? ??
          json['descricao'] as String? ??
          json['description'] as String? ??
          '',
      location: '',
      appliedAt: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : DateTime.now(),
      status: ApplicationStatusLabel.fromString(
          json['estado'] as String? ?? ''),
      logoUrl: '',
      trackingCode: json['codigo_acompanhamento'] as String?,
      interviewDate: json['entrevista_data'] != null
          ? DateTime.tryParse(json['entrevista_data'] as String)
          : null,
      interviewLocation: json['entrevista_local'] as String?,
      interviewLink: json['entrevista_link'] as String?,
    );
  }
}
