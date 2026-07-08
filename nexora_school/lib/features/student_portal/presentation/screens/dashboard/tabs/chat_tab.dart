import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/features/student_portal/domain/entities/student_mensagem.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_mensagens_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_mensagens_state.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/chat_screen.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<StudentMensagensCubit, StudentMensagensState>(
                builder: (context, state) => switch (state) {
                  StudentMensagensLoading() || StudentMensagensInitial() =>
                    const Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
                  StudentMensagensError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Color(0xFFADB5BD),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Erro ao carregar mensagens\n$message',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF8E8E93)),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.read<StudentMensagensCubit>().load(),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  StudentMensagensLoaded(:final mensagens) when mensagens.isEmpty =>
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 48,
                            color: Color(0xFFADB5BD),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Sem mensagens',
                            style: TextStyle(color: Color(0xFF8E8E93)),
                          ),
                        ],
                      ),
                    ),
                  StudentMensagensLoaded(:final mensagens) => ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: mensagens.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 76,
                      color: Color(0xFFEEEEEE),
                    ),
                    itemBuilder: (_, i) => _MensagemItem(msg: mensagens[i]),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mensagens',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Comunicados da escola',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _navy,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            SizedBox(width: 12),
            Icon(Icons.search_rounded, color: Color(0xFFADB5BD), size: 20),
            SizedBox(width: 8),
            Text(
              'Pesquisar...',
              style: TextStyle(fontSize: 14, color: Color(0xFFADB5BD)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item de mensagem ──────────────────────────────────────────────────────────

class _MensagemItem extends StatelessWidget {
  const _MensagemItem({required this.msg});
  final StudentMensagem msg;

  static const _tipoLabel = {
    'comunicado': 'Comunicado',
    'aviso': 'Aviso',
    'noticia': 'Notícia',
    'circular': 'Circular',
  };

  static const _tipoIcon = {
    'aviso': Icons.warning_amber_rounded,
    'noticia': Icons.newspaper_rounded,
    'circular': Icons.description_outlined,
  };

  String get _label => _tipoLabel[msg.tipo] ?? 'Mensagem';

  IconData get _icon =>
      _tipoIcon[msg.tipo] ?? Icons.campaign_outlined;

  String get _hora {
    final dt = msg.publicadoEm;
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  String get _preview {
    final c = msg.conteudo.trim();
    return c.length > 70 ? '${c.substring(0, 70)}…' : c;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            nome: _label,
            sub: msg.titulo,
            corpo: msg.conteudo,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        msg.titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hora,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _preview,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
