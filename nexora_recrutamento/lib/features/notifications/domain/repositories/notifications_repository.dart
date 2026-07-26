import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    bool onlyUnread,
  });
  Future<Either<Failure, Unit>> markAsRead(int id);
  Future<Either<Failure, Unit>> markAllAsRead();
}
