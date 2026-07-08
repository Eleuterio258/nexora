import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessagesRepository {
  Future<Either<Failure, List<Conversation>>> getConversations();
  Future<Either<Failure, List<Message>>> getMessages(int candidaturaId);
  Future<Either<Failure, Message>> sendMessage({
    required int candidaturaId,
    required String content,
  });
}
