import '../../domain/entities/tipo_ausencia_entity.dart';

class TipoAusenciaModel {
  final int id;
  final String codigo;
  final String nome;
  final double? diasAnuais;
  final bool remunerada;

  const TipoAusenciaModel({
    required this.id,
    required this.codigo,
    required this.nome,
    this.diasAnuais,
    required this.remunerada,
  });

  factory TipoAusenciaModel.fromJson(Map<String, dynamic> json) {
    return TipoAusenciaModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      diasAnuais: (json['dias_anuais'] as num?)?.toDouble(),
      remunerada: json['remunerada'] == true,
    );
  }

  TipoAusenciaEntity toEntity() {
    return TipoAusenciaEntity(
      id: id,
      codigo: codigo,
      nome: nome,
      diasAnuais: diasAnuais,
      remunerada: remunerada,
    );
  }
}
