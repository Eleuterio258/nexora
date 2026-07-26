import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsAsRead implements UseCase<Unit, NoParams> {
  final NotificationsRepository repository;

  const MarkAllNotificationsAsRead(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return repository.markAllAsRead();
  }
}
