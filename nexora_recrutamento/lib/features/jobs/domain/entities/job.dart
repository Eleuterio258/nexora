import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final int id;
  final String title;
  final String company;
  final String location;
  final String type;       // regime: Presencial, Híbrido, Remoto...
  final String category;   // área da vaga
  final String description;
  final String? salary;
  final String logoUrl;
  final DateTime postedAt;
  final bool isSaved;
  final String? about;
  final List<String> responsibilities;
  final List<String> requiredQualifications;
  final List<String> preferredQualifications;
  final List<String> benefits;
  final int numberOfPositions;
  final DateTime? deadline;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.category,
    required this.description,
    this.salary,
    required this.logoUrl,
    required this.postedAt,
    this.isSaved = false,
    this.about,
    this.responsibilities = const [],
    this.requiredQualifications = const [],
    this.preferredQualifications = const [],
    this.benefits = const [],
    this.numberOfPositions = 1,
    this.deadline,
  });

  Job copyWith({bool? isSaved}) => Job(
        id: id,
        title: title,
        company: company,
        location: location,
        type: type,
        category: category,
        description: description,
        salary: salary,
        logoUrl: logoUrl,
        postedAt: postedAt,
        isSaved: isSaved ?? this.isSaved,
        about: about,
        responsibilities: responsibilities,
        requiredQualifications: requiredQualifications,
        preferredQualifications: preferredQualifications,
        benefits: benefits,
        numberOfPositions: numberOfPositions,
        deadline: deadline,
      );

  @override
  List<Object?> get props => [id];
}
