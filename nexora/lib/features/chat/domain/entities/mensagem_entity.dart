import 'package:equatable/equatable.dart';

class MensagemEntity extends Equatable {
  final int id;
  final int? autorId;
  final String? autorNome;
  final String conteudo;
  final String tipo;
  final String? ficheiroUrl;
  final DateTime createdAt;

  const MensagemEntity({
    required this.id,
    this.autorId,
    this.autorNome,
    required this.conteudo,
    required this.tipo,
    this.ficheiroUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, autorId, autorNome, conteudo, tipo, ficheiroUrl, createdAt];
}
