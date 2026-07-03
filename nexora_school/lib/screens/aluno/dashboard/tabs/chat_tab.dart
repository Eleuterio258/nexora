import 'package:flutter/material.dart';
import '../sub/chat_screen.dart';

const _navy  = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  static const _conversas = [
    _Conversa(nome: 'Prof. Rafael Souza',    disciplina: 'Matemática',        ultima: 'Exercícios da pág. 45 para amanhã.',    hora: '14:32', naoLidas: 2, online: true),
    _Conversa(nome: 'Profa. Ana Lima',        disciplina: 'Língua Portuguesa', ultima: 'Muito bem, Lucas! Parabéns.',           hora: '12:10', naoLidas: 0, online: false),
    _Conversa(nome: 'Prof. Hélio Nunes',      disciplina: 'Física',            ultima: 'A prova será na próxima semana.',       hora: '10:05', naoLidas: 1, online: true),
    _Conversa(nome: 'Profa. Maria João',      disciplina: 'Biologia',          ultima: 'Traga o caderno de laboratório.',       hora: 'Ontem',  naoLidas: 0, online: false),
    _Conversa(nome: 'Prof. Thiago Martins',   disciplina: 'Química',           ultima: 'Dúvidas sobre a tabela periódica?',    hora: 'Ontem',  naoLidas: 0, online: false),
    _Conversa(nome: 'Prof. Carlos Santos',    disciplina: 'Inglês',            ultima: 'Check your homework, please.',         hora: 'Seg',    naoLidas: 0, online: false),
    _Conversa(nome: 'Prof. Marcos Vinicius',  disciplina: 'História',          ultima: 'Capítulo 8 lido para sexta-feira.',    hora: 'Seg',    naoLidas: 0, online: false),
    _Conversa(nome: 'Secretaria Escolar',     disciplina: 'Administrativo',    ultima: 'Documentos prontos para levantar.',    hora: 'Dom',    naoLidas: 3, online: true),
  ];

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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _conversas.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 76, color: Color(0xFFEEEEEE)),
                itemBuilder: (_, i) => _ConversaItem(item: _conversas[i]),
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
              Text('Mensagens', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navy)),
              SizedBox(height: 2),
              Text('Professores e escola', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            ],
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE))),
            child: const Icon(Icons.edit_outlined, color: _navy, size: 20),
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
        decoration: BoxDecoration(color: const Color(0xFFEEF0F3), borderRadius: BorderRadius.circular(10)),
        child: const Row(
          children: [
            SizedBox(width: 12),
            Icon(Icons.search_rounded, color: Color(0xFFADB5BD), size: 20),
            SizedBox(width: 8),
            Text('Pesquisar...', style: TextStyle(fontSize: 14, color: Color(0xFFADB5BD))),
          ],
        ),
      ),
    );
  }
}

// ── Item de conversa ───────────────────────────────────────────────────────────

class _ConversaItem extends StatelessWidget {
  const _ConversaItem({required this.item});
  final _Conversa item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(nome: item.nome, sub: item.disciplina, online: item.online))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.nome.split(' ').take(2).map((w) => w[0]).join(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _green),
                    ),
                  ),
                ),
                if (item.online)
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.nome,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: item.naoLidas > 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _navy,
                        ),
                      ),
                      Text(
                        item.hora,
                        style: TextStyle(
                          fontSize: 11,
                          color: item.naoLidas > 0 ? _green : const Color(0xFFADB5BD),
                          fontWeight: item.naoLidas > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.disciplina,
                    style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.ultima,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.naoLidas > 0 ? _navy : const Color(0xFF8E8E93),
                            fontWeight: item.naoLidas > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.naoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${item.naoLidas}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ── Ecrã de chat ───────────────────────────────────────────────────────────────

class _ChatScreen extends StatefulWidget {
  const _ChatScreen({required this.conversa});
  final _Conversa conversa;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _controller = TextEditingController();

  final _mensagens = <_Mensagem>[
    _Mensagem(texto: 'Bom dia, Lucas! Faltam 3 dias para a prova.', minha: false, hora: '09:10'),
    _Mensagem(texto: 'Bom dia, Professor! Estou a estudar.', minha: true, hora: '09:12'),
    _Mensagem(texto: 'Ótimo! Foca nos exercícios da pág. 42 a 45.', minha: false, hora: '09:14'),
    _Mensagem(texto: 'Sim, já fiz metade. Tenho uma dúvida na questão 8.', minha: true, hora: '09:20'),
    _Mensagem(texto: 'Exercícios da pág. 45 para amanhã.', minha: false, hora: '14:32'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      widget.conversa.nome.split(' ').take(2).map((w) => w[0]).join(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _green),
                    ),
                  ),
                ),
                if (widget.conversa.online)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversa.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navy)),
                Text(
                  widget.conversa.online ? 'Online agora' : widget.conversa.disciplina,
                  style: TextStyle(fontSize: 11, color: widget.conversa.online ? _green : const Color(0xFF8E8E93)),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _mensagens.length,
              itemBuilder: (_, i) => _BubbleItem(msg: _mensagens[i]),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFEEF0F3), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration.collapsed(hintText: 'Escreva uma mensagem...', hintStyle: TextStyle(color: Color(0xFFADB5BD), fontSize: 14)),
                style: const TextStyle(fontSize: 14, color: _navy),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (_controller.text.trim().isEmpty) return;
              setState(() {
                _mensagens.add(_Mensagem(texto: _controller.text.trim(), minha: true, hora: 'Agora'));
                _controller.clear();
              });
            },
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleItem extends StatelessWidget {
  const _BubbleItem({required this.msg});
  final _Mensagem msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: msg.minha ? _green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.minha ? 16 : 4),
            bottomRight: Radius.circular(msg.minha ? 4 : 16),
          ),
          border: msg.minha ? null : Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: msg.minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.texto, style: TextStyle(fontSize: 13, color: msg.minha ? Colors.white : _navy)),
            const SizedBox(height: 4),
            Text(msg.hora, style: TextStyle(fontSize: 10, color: msg.minha ? Colors.white70 : const Color(0xFFADB5BD))),
          ],
        ),
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _Conversa {
  const _Conversa({required this.nome, required this.disciplina, required this.ultima, required this.hora, required this.naoLidas, required this.online});
  final String nome, disciplina, ultima, hora;
  final int naoLidas;
  final bool online;
}

class _Mensagem {
  const _Mensagem({required this.texto, required this.minha, required this.hora});
  final String texto, hora;
  final bool minha;
}
