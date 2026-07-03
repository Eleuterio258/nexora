import 'package:hive_flutter/hive_flutter.dart';

part 'application_hive_model.g.dart';

@HiveType(typeId: 1)
class ApplicationHiveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int jobId;

  @HiveField(2)
  final String jobTitle;

  @HiveField(3)
  final String company;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final DateTime appliedAt;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final String logoUrl;

  ApplicationHiveModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.appliedAt,
    required this.status,
    required this.logoUrl,
  });
}
