import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../cubit/student_mensagens_cubit.dart';
import '../../../cubit/student_mensagens_state.dart';
import '../../../../domain/entities/student_mensagem.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentMensagensCubit>()..load(),
      child: const _NotificacoesView(),
    );
  }
}

class _NotificacoesView extends StatelessWidget {
  const _NotificacoesView();

  static const _tipoIcons = {
    'comunicado': Icons.campaign_outlined,
    'noticia': Icons.newspaper_outlined,
    'aviso': Icons.warning_amber_outlined,
    'evento': Icons.event_outlined,
    'circular': Icons.mail_outline_rounded,
  };

  static const _tipoColors = {
    'comunicado': Color(0xFF1565C0),
    'noticia': Color(0xFF00695C),
    'aviso': Color(0xFFF59E0B),
    'evento': Color(0xFF6750A4),
    'circular': Color(0xFFEF4444),
  };

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias atrás';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notificações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: BlocBuilder<StudentMensagensCubit, StudentMensagensState>(
        builder: (context, state) {
          if (state is StudentMensagensLoading || state is StudentMensagensInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentMensagensError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFF8E8E93), size: 40),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF8E8E93))),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<StudentMensagensCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentMensagensLoaded) {
            final msgs = state.mensagens;
            if (msgs.isEmpty) {
              return const Center(
                child: Text('Sem notificações',
                    style: TextStyle(color: Color(0xFF8E8E93))),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: msgs.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final msg = msgs[i];
                return _NotifTile(
                  msg: msg,
                  icon: _tipoIcons[msg.tipo] ?? Icons.notifications_outlined,
                  color: _tipoColors[msg.tipo] ?? const Color(0xFF8E8E93),
                  tempo: _formatDate(msg.publicadoEm),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.msg,
    required this.icon,
    required this.color,
    required this.tempo,
  });
  final StudentMensagem msg;
  final IconData icon;
  final Color color;
  final String tempo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(msg.titulo,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _navy)),
                    ),
                    if (tempo.isNotEmpty)
                      Text(tempo,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFADB5BD))),
                  ],
                ),
                if (msg.conteudo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(msg.conteudo,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 5),
                Text(
                  msg.tipo.isNotEmpty
                      ? msg.tipo[0].toUpperCase() + msg.tipo.substring(1)
                      : '',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
