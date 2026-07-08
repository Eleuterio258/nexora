import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../../core/storage/local_store.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';

// Mesma base URL usada por DioRestClient
// (core/rest_client/dio/dio_rest_client.dart) — manter em sincronia até
// existir uma constante partilhada entre os dois.
const _kSocketBaseUrl = 'http://192.168.168.219:8080';

/// Liga à conversa candidato↔recrutador em tempo real via Socket.IO.
/// Complementa o REST existente (MessagesRemoteDataSource): o envio de
/// mensagens continua por REST, este serviço só recebe as que chegam ao vivo.
class ChatSocketService {
  final LocalStore _store;
  socket_io.Socket? _socket;
  final _messagesController = StreamController<Message>.broadcast();

  ChatSocketService({required LocalStore store}) : _store = store;

  Stream<Message> get messages => _messagesController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await _store.read('auth_token');
    if (token == null) return;

    _socket = socket_io.io(
      _kSocketBaseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('nova_mensagem', (data) {
      _messagesController.add(
        MessageModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    });
    _socket!.connect();
  }

  void joinCandidatura(int candidaturaId) {
    _socket?.emit('join_candidatura', candidaturaId);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
