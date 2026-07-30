import 'package:equatable/equatable.dart';

class TipoAusenciaEntity extends Equatable {
  final int id;
  final String codigo;
  final String nome;
  final double? diasAnuais;
  final bool remunerada;

  const TipoAusenciaEntity({
    required this.id,
    required this.codigo,
    required this.nome,
    this.diasAnuais,
    required this.remunerada,
  });

  @override
  List<Object?> get props => [id, codigo, nome, diasAnuais, remunerada];
}
