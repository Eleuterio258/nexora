import '../../domain/entities/pedido_ferias_entity.dart';
import '../../domain/entities/pedido_ferias_status.dart';

class PedidoFeriasModel {
  final int id;
  final String? tipoNome;
  final String dataInicio;
  final String dataFim;
  final int? dias;
  final String? motivo;
  final String estado;
  final String criadoEm;

  const PedidoFeriasModel({
    required this.id,
    this.tipoNome,
    required this.dataInicio,
    required this.dataFim,
    this.dias,
    this.motivo,
    required this.estado,
    required this.criadoEm,
  });

  factory PedidoFeriasModel.fromJson(Map<String, dynamic> json) {
    return PedidoFeriasModel(
      id: (json['id'] as num).toInt(),
      tipoNome: json['tipo_nome']?.toString(),
      dataInicio: json['data_inicio']?.toString() ?? '',
      dataFim: json['data_fim']?.toString() ?? '',
      dias: (json['dias'] as num?)?.toInt(),
      motivo: json['motivo']?.toString(),
      estado: json['estado']?.toString() ?? 'pendente',
      criadoEm: json['criado_em']?.toString() ?? '',
    );
  }

  PedidoFeriasEntity toEntity() {
    return PedidoFeriasEntity(
      id: id,
      tipoNome: tipoNome,
      dataInicio: DateTime.tryParse(dataInicio) ?? DateTime.now(),
      dataFim: DateTime.tryParse(dataFim) ?? DateTime.now(),
      dias: dias,
      motivo: motivo,
      estado: PedidoFeriasStatus.fromString(estado),
      criadoEm: DateTime.tryParse(criadoEm) ?? DateTime.now(),
    );
  }
}
