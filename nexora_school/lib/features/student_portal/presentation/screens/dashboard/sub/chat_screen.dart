import 'package:flutter/material.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.nome,
    required this.sub,
    this.online = false,
    this.corpo,
  });

  final String nome;
  final String sub;
  final bool online;
  final String? corpo;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  late final List<_Msg> _mensagens;

  String get _initials =>
      widget.nome.split(' ').take(2).map((w) => w[0]).join();

  @override
  void initState() {
    super.initState();
    _mensagens = widget.corpo != null
        ? [_Msg(texto: widget.corpo!, minha: false, hora: _horaAgora())]
        : [_Msg(texto: 'Olá! Como posso ajudar?', minha: false, hora: '09:10')];
  }

  static String _horaAgora() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _mensagens.add(_Msg(texto: texto, minha: true, hora: 'Agora'));
      _controller.clear();
    });
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _navy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ),
                ),
                if (widget.online)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                Text(
                  widget.online ? 'Online agora' : widget.sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.online ? _green : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _mensagens.length,
              itemBuilder: (_, i) => _Bubble(msg: _mensagens[i]),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Escreva uma mensagem...',
                  hintStyle: TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
                ),
                style: const TextStyle(fontSize: 14, color: _navy),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _enviar,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
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
          crossAxisAlignment: msg.minha
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.texto,
              style: TextStyle(
                fontSize: 13,
                color: msg.minha ? Colors.white : _navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.hora,
              style: TextStyle(
                fontSize: 10,
                color: msg.minha ? Colors.white70 : const Color(0xFFADB5BD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  const _Msg({required this.texto, required this.minha, required this.hora});
  final String texto, hora;
  final bool minha;
}
