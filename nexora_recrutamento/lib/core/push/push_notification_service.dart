import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../rest_client/rest_client.dart';
import '../rest_client/rest_client_exception.dart';

/// Pede permissão de notificações, obtém o token FCM do dispositivo e
/// regista-o no backend (POST /candidatos/push-token) — para que o
/// candidato receba push de novas mensagens/actualizações das suas
/// candidaturas (ver internal/push no backend).
///
/// Requer sessão de candidato válida (client.auth()); por isso só deve
/// ser chamado depois de um login bem-sucedido (ver app.dart).
class PushNotificationService {
  final RestClient client;
  bool _started = false;

  PushNotificationService({required this.client});

  Future<void> start() async {
    if (_started) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    _started = true;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _register(token);

    messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String token) async {
    try {
      await client.auth().post(
        '/api/public/recrutamento/candidatos/push-token',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } on RestClientException {
      // Falha ao registar o token não deve impedir o uso da app — o
      // candidato simplesmente não recebe push até ao próximo arranque.
    }
  }
}
