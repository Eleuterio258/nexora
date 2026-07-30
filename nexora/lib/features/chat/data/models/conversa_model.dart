import '../../domain/entities/conversa_entity.dart';

class ConversaModel {
  final int id;
  final String? nome;
  final String tipo;
  final String? ultimaMensagem;
  final String? ultimaData;
  final int naoLidas;

  const ConversaModel({
    required this.id,
    this.nome,
    required this.tipo,
    this.ultimaMensagem,
    this.ultimaData,
    required this.naoLidas,
  });

  factory ConversaModel.fromJson(Map<String, dynamic> json) {
    return ConversaModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString(),
      tipo: json['tipo']?.toString() ?? 'individual',
      ultimaMensagem: json['ultima_mensagem']?.toString(),
      ultimaData: json['ultima_data']?.toString(),
      naoLidas: (json['nao_lidas'] as num?)?.toInt() ?? 0,
    );
  }

  ConversaEntity toEntity() {
    return ConversaEntity(
      id: id,
      nome: nome,
      tipo: tipo,
      ultimaMensagem: ultimaMensagem,
      ultimaData: ultimaData != null ? DateTime.tryParse(ultimaData!) : null,
      naoLidas: naoLidas,
    );
  }
}
