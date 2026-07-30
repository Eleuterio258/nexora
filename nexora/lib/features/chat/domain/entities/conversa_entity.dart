import 'package:equatable/equatable.dart';

class ConversaEntity extends Equatable {
  final int id;
  final String? nome;
  final String tipo;
  final String? ultimaMensagem;
  final DateTime? ultimaData;
  final int naoLidas;

  const ConversaEntity({
    required this.id,
    this.nome,
    required this.tipo,
    this.ultimaMensagem,
    this.ultimaData,
    required this.naoLidas,
  });

  String get nomeExibicao => nome ?? 'Conversa';

  @override
  List<Object?> get props => [id, nome, tipo, ultimaMensagem, ultimaData, naoLidas];
}
