import 'package:equatable/equatable.dart';

enum ApplicationStatus { received, inReview, interview, approved, rejected }

extension ApplicationStatusLabel on ApplicationStatus {
  String get pt {
    switch (this) {
      case ApplicationStatus.received:  return 'Recebida';
      case ApplicationStatus.inReview:  return 'Em Análise';
      case ApplicationStatus.interview: return 'Entrevista';
      case ApplicationStatus.approved:  return 'Aprovada';
      case ApplicationStatus.rejected:  return 'Não Seleccionada';
    }
  }

  String get en {
    switch (this) {
      case ApplicationStatus.received:  return 'Received';
      case ApplicationStatus.inReview:  return 'In Review';
      case ApplicationStatus.interview: return 'Interview';
      case ApplicationStatus.approved:  return 'Approved';
      case ApplicationStatus.rejected:  return 'Rejected';
    }
  }

  /// Mapeia directamente os valores de `estado` usados por
  /// `recrutamento.candidaturas` no backend: recebida/em_analise/
  /// entrevista/aprovada/rejeitada.
  static ApplicationStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'em_analise':
      case 'in_review':
      case 'in review':  return ApplicationStatus.inReview;
      case 'entrevista':
      case 'interview':  return ApplicationStatus.interview;
      case 'aprovada':
      case 'approved':
      case 'offer':      return ApplicationStatus.approved;
      case 'rejeitada':
      case 'rejected':   return ApplicationStatus.rejected;
      default:           return ApplicationStatus.received;
    }
  }
}

class Application extends Equatable {
  final int id;
  final int jobId;
  final String jobTitle;
  final String company;
  final String jobDescription;
  final String location;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final String logoUrl;
  final String? trackingCode;
  final DateTime? interviewDate;
  final String? interviewLocation;
  final String? interviewLink;

  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    required this.location,
    required this.appliedAt,
    required this.status,
    required this.logoUrl,
    this.trackingCode,
    this.interviewDate,
    this.interviewLocation,
    this.interviewLink,
  });

  @override
  List<Object> get props => [id];
}
