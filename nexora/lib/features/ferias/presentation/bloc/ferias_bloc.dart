import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/ferias_repository.dart';
import '../../domain/usecases/cancelar_pedido_ferias_usecase.dart';
import '../../domain/usecases/criar_pedido_ferias_usecase.dart';
import '../../domain/usecases/get_meus_pedidos_ferias_usecase.dart';
import '../../domain/usecases/get_tipos_ausencia_usecase.dart';
import 'ferias_event.dart';
import 'ferias_state.dart';

class FeriasBloc extends Bloc<FeriasEvent, FeriasState> {
  final GetTiposAusenciaUseCase getTiposAusenciaUseCase;
  final GetMeusPedidosFeriasUseCase getMeusPedidosUseCase;
  final CriarPedidoFeriasUseCase criarPedidoUseCase;
  final CancelarPedidoFeriasUseCase cancelarPedidoUseCase;

  FeriasBloc({
    required this.getTiposAusenciaUseCase,
    required this.getMeusPedidosUseCase,
    required this.criarPedidoUseCase,
    required this.cancelarPedidoUseCase,
  }) : super(FeriasInitial()) {
    on<LoadTiposAusencia>(_onLoadTipos);
    on<LoadMeusPedidosFerias>(_onLoadPedidos);
    on<CriarPedidoFerias>(_onCriarPedido);
    on<CancelarPedidoFerias>(_onCancelarPedido);
  }

  Future<void> _onLoadTipos(
    LoadTiposAusencia event,
    Emitter<FeriasState> emit,
  ) async {
    emit(FeriasLoading());
    final result = await getTiposAusenciaUseCase(const NoParams());
    result.fold(
      (failure) => emit(FeriasFailure(message: failure.message)),
      (tipos) => emit(TiposAusenciaLoaded(tipos: tipos)),
    );
  }

  Future<void> _onLoadPedidos(
    LoadMeusPedidosFerias event,
    Emitter<FeriasState> emit,
  ) async {
    emit(FeriasLoading());
    final result = await getMeusPedidosUseCase(const NoParams());
    result.fold(
      (failure) => emit(FeriasFailure(message: failure.message)),
      (pedidos) => emit(MeusPedidosFeriasLoaded(pedidos: pedidos)),
    );
  }

  Future<void> _onCriarPedido(
    CriarPedidoFerias event,
    Emitter<FeriasState> emit,
  ) async {
    emit(FeriasLoading());
    final result = await criarPedidoUseCase(
      CriarPedidoFeriasParams(
        tipoId: event.tipoId,
        dataInicio: event.dataInicio,
        dataFim: event.dataFim,
        motivo: event.motivo,
      ),
    );
    result.fold(
      (failure) => emit(FeriasFailure(message: failure.message)),
      (id) => emit(PedidoFeriasCriado(id: id)),
    );
  }

  Future<void> _onCancelarPedido(
    CancelarPedidoFerias event,
    Emitter<FeriasState> emit,
  ) async {
    emit(FeriasLoading());
    final result = await cancelarPedidoUseCase(event.id);
    result.fold(
      (failure) => emit(FeriasFailure(message: failure.message)),
      (_) => emit(PedidoFeriasCancelado()),
    );
  }
}
