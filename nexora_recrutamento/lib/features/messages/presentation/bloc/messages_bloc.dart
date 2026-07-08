import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../../../core/usecases/usecase.dart';
import 'messages_event.dart';
import 'messages_state.dart';

export 'messages_event.dart';
export 'messages_state.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final GetConversations _getConversations;

  MessagesBloc({required GetConversations getConversations})
      : _getConversations = getConversations,
        super(const MessagesInitial()) {
    on<ConversationsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      ConversationsLoadRequested event, Emitter<MessagesState> emit) async {
    emit(const MessagesLoading());
    final result = await _getConversations(const NoParams());
    result.fold(
      (f) => emit(MessagesFailureState(f.message)),
      (conversations) => emit(ConversationsLoaded(conversations)),
    );
  }
}
