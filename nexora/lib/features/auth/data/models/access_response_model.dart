import 'module_access_model.dart';

class AccessResponseModel {
  final int userId;
  final int tenantId;
  final String type;
  final String scope;
  final int? roleId;
  final String? roleName;
  final List<ModuleAccessModel> modules;
  final List<String> features;

  AccessResponseModel({
    required this.userId,
    required this.tenantId,
    required this.type,
    required this.scope,
    this.roleId,
    this.roleName,
    required this.modules,
    required this.features,
  });

  factory AccessResponseModel.fromJson(Map<String, dynamic> json) {
    return AccessResponseModel(
      userId: json['user_id'] as int,
      tenantId: json['tenant_id'] as int,
      type: json['tipo'] as String,
      scope: json['escopo'] as String,
      roleId: json['cargo_id'] as int?,
      roleName: json['cargo_nome'] as String?,
      modules: (json['modulos'] as List<dynamic>?)
              ?.map((e) => ModuleAccessModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      features:
          (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }
}
