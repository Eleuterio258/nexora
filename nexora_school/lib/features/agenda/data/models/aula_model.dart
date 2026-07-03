import '../../domain/entities/aula_entity.dart';

class AulaModel extends AulaEntity {
  const AulaModel({
    required super.subject,
    required super.teacher,
    required super.activity,
    required super.time,
    required super.icon,
    required super.color,
    required super.weekday,
  });

  factory AulaModel.fromEntity(AulaEntity entity) => AulaModel(
    subject: entity.subject,
    teacher: entity.teacher,
    activity: entity.activity,
    time: entity.time,
    icon: entity.icon,
    color: entity.color,
    weekday: entity.weekday,
  );
}
