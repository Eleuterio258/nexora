import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_notifications_as_read.dart';
import '../../domain/usecases/mark_notification_as_read.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

export 'notifications_event.dart';
export 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotifications _getNotifications;
  final MarkNotificationAsRead _markAsRead;
  final MarkAllNotificationsAsRead _markAllAsRead;

  NotificationsBloc({
    required GetNotifications getNotifications,
    required MarkNotificationAsRead markAsRead,
    required MarkAllNotificationsAsRead markAllAsRead,
  })  : _getNotifications = getNotifications,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead,
        super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkedAsRead>(_onMarkAsRead);
    on<AllNotificationsMarkedAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    final result = await _getNotifications(
      GetNotificationsParams(onlyUnread: event.onlyUnread),
    );
    result.fold(
      (failure) => emit(NotificationsFailure(failure.message)),
      (notifications) => emit(NotificationsLoaded(notifications)),
    );
  }

  Future<void> _onMarkAsRead(
    NotificationMarkedAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      final updated = currentState.notifications
          .map((n) => n.id == event.id ? n.copyWith(lida: true) : n)
          .toList();
      emit(NotificationsLoaded(updated));
    }

    final result = await _markAsRead(event.id);
    result.fold(
      (failure) => emit(NotificationsFailure(failure.message)),
      (_) {},
    );
  }

  Future<void> _onMarkAllAsRead(
    AllNotificationsMarkedAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      final updated = currentState.notifications
          .map((n) => n.copyWith(lida: true))
          .toList();
      emit(NotificationsLoaded(updated));
    }

    final result = await _markAllAsRead(const NoParams());
    result.fold(
      (failure) => emit(NotificationsFailure(failure.message)),
      (_) {},
    );
  }
}
