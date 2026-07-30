import '../../domain/entities/mensagem_entity.dart';

class MensagemModel {
  final int id;
  final int? autorId;
  final String? autorNome;
  final String conteudo;
  final String tipo;
  final String? ficheiroUrl;
  final String createdAt;

  const MensagemModel({
    required this.id,
    this.autorId,
    this.autorNome,
    required this.conteudo,
    required this.tipo,
    this.ficheiroUrl,
    required this.createdAt,
  });

  factory MensagemModel.fromJson(Map<String, dynamic> json) {
    return MensagemModel(
      id: (json['id'] as num).toInt(),
      autorId: (json['autor_id'] as num?)?.toInt(),
      autorNome: json['autor_nome']?.toString(),
      conteudo: json['conteudo']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'texto',
      ficheiroUrl: json['ficheiro_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  MensagemEntity toEntity() {
    return MensagemEntity(
      id: id,
      autorId: autorId,
      autorNome: autorNome,
      conteudo: conteudo,
      tipo: tipo,
      ficheiroUrl: ficheiroUrl,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }
}
