import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nome,
    required super.email,
    required super.token,
    super.refreshToken,
    required super.permissoes,
    super.tenantId,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String token = '',
    String refreshToken = '',
  }) {
    return UserModel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String,
      token: token,
      refreshToken: refreshToken,
      // API devolve as permissões em "escopo" (ex.: ["portal_candidato"]);
      // "permissoes" é mantido como alternativa para outras origens.
      permissoes: (json['permissoes'] as List<dynamic>? ??
              json['escopo'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      tenantId: json['tenant_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'permissoes': permissoes,
        'tenant_id': tenantId,
      };
}
