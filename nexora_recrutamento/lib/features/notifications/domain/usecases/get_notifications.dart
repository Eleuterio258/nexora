import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/notification_model.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsParams {
  final bool onlyUnread;

  const GetNotificationsParams({this.onlyUnread = false});
}

class GetNotifications
    implements UseCase<List<NotificationModel>, GetNotificationsParams> {
  final NotificationsRepository repository;

  const GetNotifications(this.repository);

  @override
  Future<Either<Failure, List<NotificationModel>>> call(
    GetNotificationsParams params,
  ) {
    return repository.getNotifications(onlyUnread: params.onlyUnread);
  }
}
