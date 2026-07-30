import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/pedido_ferias_entity.dart';
import '../../domain/entities/tipo_ausencia_entity.dart';
import '../../domain/repositories/ferias_repository.dart';
import '../datasources/ferias_remote_datasource.dart';

class FeriasRepositoryImpl implements FeriasRepository {
  final FeriasRemoteDataSource remoteDataSource;

  FeriasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TipoAusenciaEntity>>> getTiposAusencia() async {
    try {
      final tipos = await remoteDataSource.getTiposAusencia();
      return Right(tipos.map((t) => t.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, List<PedidoFeriasEntity>>> getMeusPedidos() async {
    try {
      final pedidos = await remoteDataSource.getMeusPedidos();
      return Right(pedidos.map((p) => p.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, int>> criarPedido(
    CriarPedidoFeriasParams params,
  ) async {
    try {
      final id = await remoteDataSource.criarPedido(
        tipoId: params.tipoId,
        dataInicio: _formatDate(params.dataInicio),
        dataFim: _formatDate(params.dataFim),
        motivo: params.motivo,
      );
      return Right(id);
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> cancelarPedido(int id) async {
    try {
      await remoteDataSource.cancelarPedido(id);
      return const Right(null);
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
