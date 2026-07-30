import '../../domain/entities/module_access_entity.dart';

class ModuleAccessModel {
  final String module;
  final String? color;
  final List<String> actions;

  ModuleAccessModel({
    required this.module,
    this.color,
    this.actions = const [],
  });

  factory ModuleAccessModel.fromJson(Map<String, dynamic> json) {
    return ModuleAccessModel(
      module: json['modulo'] as String,
      color: json['cor'] as String?,
      actions:
          (json['acoes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }

  factory ModuleAccessModel.fromEntity(ModuleAccessEntity entity) {
    return ModuleAccessModel(
      module: entity.module,
      color: entity.color,
      actions: entity.actions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modulo': module,
      'cor': color,
      'acoes': actions,
    };
  }

  ModuleAccessEntity toEntity() {
    return ModuleAccessEntity(
      module: module,
      color: color,
      actions: actions,
    );
  }
}
