import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/enviar_mensagem_usecase.dart';
import '../../domain/usecases/get_conversas_usecase.dart';
import '../../domain/usecases/get_mensagens_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversasUseCase getConversasUseCase;
  final GetMensagensUseCase getMensagensUseCase;
  final EnviarMensagemUseCase enviarMensagemUseCase;

  ChatBloc({
    required this.getConversasUseCase,
    required this.getMensagensUseCase,
    required this.enviarMensagemUseCase,
  }) : super(ChatInitial()) {
    on<LoadConversas>(_onLoadConversas);
    on<LoadMensagens>(_onLoadMensagens);
    on<EnviarMensagem>(_onEnviarMensagem);
  }

  Future<void> _onLoadConversas(
    LoadConversas event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await getConversasUseCase(const NoParams());
    result.fold(
      (failure) => emit(ChatFailure(message: failure.message)),
      (conversas) => emit(ConversasLoaded(conversas: conversas)),
    );
  }

  Future<void> _onLoadMensagens(
    LoadMensagens event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await getMensagensUseCase(event.conversaId);
    result.fold(
      (failure) => emit(ChatFailure(message: failure.message)),
      (mensagens) => emit(MensagensLoaded(mensagens: mensagens)),
    );
  }

  Future<void> _onEnviarMensagem(
    EnviarMensagem event,
    Emitter<ChatState> emit,
  ) async {
    final result = await enviarMensagemUseCase(
      EnviarMensagemParams(
        conversaId: event.conversaId,
        conteudo: event.conteudo,
      ),
    );
    await result.fold(
      (failure) async => emit(ChatFailure(message: failure.message)),
      (_) async {
        final refreshed = await getMensagensUseCase(event.conversaId);
        refreshed.fold(
          (failure) => emit(ChatFailure(message: failure.message)),
          (mensagens) => emit(MensagensLoaded(mensagens: mensagens)),
        );
      },
    );
  }
}
