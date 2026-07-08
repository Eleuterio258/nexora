import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/chat_socket_service.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_conversation_messages.dart';
import '../../domain/usecases/send_conversation_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

export 'chat_event.dart';
export 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationMessages _getMessages;
  final SendConversationMessage _sendMessage;
  final ChatSocketService _socketService;
  StreamSubscription<Message>? _socketSub;

  ChatBloc({
    required GetConversationMessages getMessages,
    required SendConversationMessage sendMessage,
    required ChatSocketService socketService,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _socketService = socketService,
        super(const ChatInitial()) {
    on<ChatMessagesLoadRequested>(_onLoad);
    on<ChatMessageSendRequested>(_onSend);
    on<ChatMessageReceived>(_onReceived);

    _socketSub = _socketService.messages.listen(
      (message) => add(ChatMessageReceived(message)),
    );
  }

  Future<void> _onLoad(
      ChatMessagesLoadRequested event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    await _socketService.connect();
    _socketService.joinCandidatura(event.candidaturaId);
    final result = await _getMessages(
      GetConversationMessagesParams(event.candidaturaId),
    );
    result.fold(
      (f) => emit(ChatFailureState(f.message)),
      (messages) => emit(ChatLoaded(messages)),
    );
  }

  Future<void> _onSend(
      ChatMessageSendRequested event, Emitter<ChatState> emit) async {
    final current = state;
    final existing = current is ChatLoaded ? current.messages : const <Message>[];
    if (current is ChatLoaded) {
      emit(ChatLoaded(current.messages, sending: true));
    }

    final result = await _sendMessage(
      SendConversationMessageParams(
        candidaturaId: event.candidaturaId,
        content: event.content,
      ),
    );
    result.fold(
      (f) => emit(ChatFailureState(f.message)),
      (message) => emit(ChatLoaded([...existing, message])),
    );
  }

  Future<void> _onReceived(
      ChatMessageReceived event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (current.messages.any((m) => m.id == event.message.id)) return;
    emit(ChatLoaded([...current.messages, event.message], sending: current.sending));
  }

  @override
  Future<void> close() {
    _socketSub?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
