import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nome,
    required super.email,
    required super.token,
    required super.permissoes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String token = ''}) {
    return UserModel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String,
      token: token,
      permissoes: (json['permissoes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'permissoes': permissoes,
      };
}
