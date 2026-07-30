import 'package:equatable/equatable.dart';

class ModuleAccessEntity extends Equatable {
  final String module;
  final String? color;
  final List<String> actions;

  const ModuleAccessEntity({
    required this.module,
    this.color,
    this.actions = const [],
  });

  @override
  List<Object?> get props => [module, color, actions];
}
