import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/mensagem_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ConversaPage extends StatelessWidget {
  final int conversaId;
  final String nome;

  const ConversaPage({super.key, required this.conversaId, required this.nome});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ChatBloc>()..add(LoadMensagens(conversaId: conversaId)),
      child: _ConversaView(conversaId: conversaId, nome: nome),
    );
  }
}

class _ConversaView extends StatefulWidget {
  final int conversaId;
  final String nome;

  const _ConversaView({required this.conversaId, required this.nome});

  @override
  State<_ConversaView> createState() => _ConversaViewState();
}

class _ConversaViewState extends State<_ConversaView> {
  final _mensagemController = TextEditingController();
  final _scrollController = ScrollController();

  int? get _meuUserId => sl<SessionManager>().user?.id;

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviar(BuildContext context) {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;

    context.read<ChatBloc>().add(
          EnviarMensagem(conversaId: widget.conversaId, conteudo: texto),
        );
    _mensagemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nome)),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
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

                final mensagens = state is MensagensLoaded ? state.mensagens : <MensagemEntity>[];

                if (mensagens.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ainda não há mensagens. Diz olá!',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = mensagens[index];
                    final isMinha = mensagem.autorId != null && mensagem.autorId == _meuUserId;
                    return _MensagemBubble(mensagem: mensagem, isMinha: isMinha);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(context),
                      decoration: const InputDecoration(
                        hintText: 'Escreve uma mensagem…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _enviar(context),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MensagemBubble extends StatelessWidget {
  final MensagemEntity mensagem;
  final bool isMinha;

  const _MensagemBubble({required this.mensagem, required this.isMinha});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMinha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMinha ? AppColors.brandAccent : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMinha && mensagem.autorNome != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  mensagem.autorNome!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandAccentDark,
                  ),
                ),
              ),
            Text(
              mensagem.conteudo,
              style: TextStyle(color: isMinha ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(mensagem.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isMinha ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
