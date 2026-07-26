import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  final bool onlyUnread;

  const NotificationsLoadRequested({this.onlyUnread = false});

  @override
  List<Object?> get props => [onlyUnread];
}

class NotificationMarkedAsRead extends NotificationsEvent {
  final int id;

  const NotificationMarkedAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class AllNotificationsMarkedAsRead extends NotificationsEvent {
  const AllNotificationsMarkedAsRead();
}
