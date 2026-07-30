import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/pedido_ferias_model.dart';
import '../models/tipo_ausencia_model.dart';

abstract class FeriasRemoteDataSource {
  Future<List<TipoAusenciaModel>> getTiposAusencia();

  Future<List<PedidoFeriasModel>> getMeusPedidos();

  Future<int> criarPedido({
    required int tipoId,
    required String dataInicio,
    required String dataFim,
    String? motivo,
  });

  Future<void> cancelarPedido(int id);
}

class FeriasRemoteDataSourceImpl implements FeriasRemoteDataSource {
  final RestClient restClient;

  FeriasRemoteDataSourceImpl({required this.restClient});

  @override
  Future<List<TipoAusenciaModel>> getTiposAusencia() async {
    try {
      final response = await restClient.auth().get<List<dynamic>>(
        '/api/pedido-ferias/tipos',
      );

      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(TipoAusenciaModel.fromJson)
          .toList();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao carregar os tipos de ausência.');
    }
  }

  @override
  Future<List<PedidoFeriasModel>> getMeusPedidos() async {
    try {
      final response = await restClient.auth().get<List<dynamic>>(
        '/api/pedido-ferias',
      );

      final data = response.data ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(PedidoFeriasModel.fromJson)
          .toList();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao carregar os pedidos de férias.');
    }
  }

  @override
  Future<int> criarPedido({
    required int tipoId,
    required String dataInicio,
    required String dataFim,
    String? motivo,
  }) async {
    try {
      final response = await restClient.auth().post<Map<String, dynamic>>(
        '/api/pedido-ferias',
        data: {
          'tipo_id': tipoId,
          'data_inicio': dataInicio,
          'data_fim': dataFim,
          'motivo': motivo,
        },
      );

      final data = response.data ?? {};
      return (data['id'] as num).toInt();
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao submeter o pedido de férias.');
    }
  }

  @override
  Future<void> cancelarPedido(int id) async {
    try {
      await restClient.auth().post<void>('/api/pedido-ferias/$id/cancelar');
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao cancelar o pedido.');
    }
  }

  Never _handleError(RestClientException e, String fallback) {
    if (e.isTimeout) {
      throw Exception(
        'O servidor demorou demasiado tempo a responder. Tenta novamente.',
      );
    }

    final data = e.response.data;
    final message = data is Map
        ? (data['detail'] ?? data['error'] ?? data['mensagem'])
        : null;
    throw Exception(message?.toString() ?? fallback);
  }
}
