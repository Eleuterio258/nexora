import 'package:hive_flutter/hive_flutter.dart';

part 'job_hive_model.g.dart';

@HiveType(typeId: 0)
class JobHiveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String company;

  @HiveField(3)
  final String location;

  @HiveField(4)
  final String type;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final String? salary;

  @HiveField(8)
  final String logoUrl;

  @HiveField(9)
  final DateTime postedAt;

  @HiveField(10)
  final bool isSaved;

  JobHiveModel({
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
}
