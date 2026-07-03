import 'package:equatable/equatable.dart';

enum ApplicationStatus { received, inReview, interview, offer, rejected }

extension ApplicationStatusLabel on ApplicationStatus {
  String get pt {
    switch (this) {
      case ApplicationStatus.received:   return 'Recebida';
      case ApplicationStatus.inReview:   return 'Em Análise';
      case ApplicationStatus.interview:  return 'Entrevista';
      case ApplicationStatus.offer:      return 'Proposta';
      case ApplicationStatus.rejected:   return 'Rejeitada';
    }
  }

  String get en {
    switch (this) {
      case ApplicationStatus.received:   return 'Received';
      case ApplicationStatus.inReview:   return 'In Review';
      case ApplicationStatus.interview:  return 'Interview';
      case ApplicationStatus.offer:      return 'Offer';
      case ApplicationStatus.rejected:   return 'Rejected';
    }
  }

  static ApplicationStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'em_analise':
      case 'in_review':
      case 'in review':  return ApplicationStatus.inReview;
      case 'entrevista':
      case 'interview':  return ApplicationStatus.interview;
      case 'proposta':
      case 'offer':      return ApplicationStatus.offer;
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
  final String location;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final String logoUrl;

  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.appliedAt,
    required this.status,
    required this.logoUrl,
  });

  @override
  List<Object> get props => [id];
}
