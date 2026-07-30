import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/conversa_tile.dart';
import 'conversa_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatBloc>()..add(const LoadConversas()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  Future<void> _abrirConversa(BuildContext context, int id, String nome) async {
    final bloc = context.read<ChatBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversaPage(conversaId: id, nome: nome),
      ),
    );
    bloc.add(const LoadConversas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversas = state is ConversasLoaded ? state.conversas : [];

          if (conversas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ainda não tens conversas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ChatBloc>().add(const LoadConversas()),
            child: ListView.separated(
              itemCount: conversas.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final conversa = conversas[index];
                return ConversaTile(
                  conversa: conversa,
                  onTap: () => _abrirConversa(
                    context,
                    conversa.id,
                    conversa.nomeExibicao,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
