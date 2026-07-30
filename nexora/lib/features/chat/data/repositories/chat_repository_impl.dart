import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/conversa_entity.dart';
import '../../domain/entities/mensagem_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ConversaEntity>>> getConversas() async {
    try {
      final conversas = await remoteDataSource.getConversas();
      return Right(conversas.map((c) => c.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, List<MensagemEntity>>> getMensagens(
    int conversaId,
  ) async {
    try {
      final mensagens = await remoteDataSource.getMensagens(conversaId);
      return Right(mensagens.map((m) => m.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, int>> enviarMensagem(
    EnviarMensagemParams params,
  ) async {
    try {
      final id = await remoteDataSource.enviarMensagem(
        conversaId: params.conversaId,
        conteudo: params.conteudo,
      );
      return Right(id);
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
