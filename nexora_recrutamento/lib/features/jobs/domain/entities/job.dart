import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final int id;
  final String title;
  final String company;
  final String location;
  final String type;       // Full-time, Part-time, Remote, Hybrid
  final String category;
  final String description;
  final String? salary;
  final String logoUrl;
  final DateTime postedAt;
  final bool isSaved;

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
      );

  @override
  List<Object?> get props => [id];
}
