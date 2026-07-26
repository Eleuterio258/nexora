import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationAsRead implements UseCase<Unit, int> {
  final NotificationsRepository repository;

  const MarkNotificationAsRead(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.markAsRead(params);
  }
}
