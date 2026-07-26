import '../../../../core/error/rest_exception_mapper.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({bool onlyUnread = false});
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final RestClient client;

  const NotificationsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationModel>> getNotifications({
    bool onlyUnread = false,
  }) async {
    try {
      final res = await client.auth().get<List<dynamic>>(
        '/api/public/recrutamento/candidatos/notificacoes',
        queryParameters: onlyUnread ? {'nao_lidas': 'true'} : null,
      );
      final list = res.data ?? [];
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await client.auth().put<dynamic>(
        '/api/public/recrutamento/candidatos/notificacoes/$id/lida',
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await client.auth().put<dynamic>(
        '/api/public/recrutamento/candidatos/notificacoes/lidas',
      );
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
