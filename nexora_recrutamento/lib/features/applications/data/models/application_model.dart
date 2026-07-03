import '../../domain/entities/application.dart';

class ApplicationModel extends Application {
  const ApplicationModel({
    required super.id,
    required super.jobId,
    required super.jobTitle,
    required super.company,
    required super.location,
    required super.appliedAt,
    required super.status,
    required super.logoUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final vaga = json['vaga'] as Map<String, dynamic>? ?? {};
    return ApplicationModel(
      id: json['id'] as int,
      jobId: json['vaga_id'] as int? ?? vaga['id'] as int? ?? 0,
      jobTitle: vaga['titulo'] as String? ?? json['job_title'] as String? ?? '',
      company: vaga['empresa'] as String? ?? json['company'] as String? ?? '',
      location: vaga['localizacao'] as String? ?? json['location'] as String? ?? '',
      appliedAt: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : DateTime.now(),
      status: ApplicationStatusLabel.fromString(
          json['estado'] as String? ?? json['status'] as String? ?? ''),
      logoUrl: vaga['logo_url'] as String? ?? '',
    );
  }
}
