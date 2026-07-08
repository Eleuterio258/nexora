import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  final MessagesRemoteDataSource remote;

  const MessagesRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      return Right(await remote.getConversations());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(int candidaturaId) async {
    try {
      return Right(await remote.getMessages(candidaturaId));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int candidaturaId,
    required String content,
  }) async {
    try {
      return Right(await remote.sendMessage(candidaturaId, content));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}
