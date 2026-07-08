import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);

class AjudaFaqScreen extends StatefulWidget {
  const AjudaFaqScreen({super.key});

  @override
  State<AjudaFaqScreen> createState() => _AjudaFaqScreenState();
}

class _AjudaFaqScreenState extends State<AjudaFaqScreen> {
  int? _expandedIndex;

  static const _faqs = [
    _Faq(
      pergunta: 'Como consultar as minhas notas?',
      resposta:
          'Aceda ao separador "Boletim" na barra de navegação inferior. Pode seleccionar o trimestre no selector de período no topo da página.',
    ),
    _Faq(
      pergunta: 'Como pagar a propina pelo M-Pesa?',
      resposta:
          'No separador "Financeiro", toque no botão "Pagar" na propina pendente. Seleccione "M-Pesa" e marque o USSD *150*1# no seu telemóvel com a referência indicada.',
    ),
    _Faq(
      pergunta: 'Como ver o meu horário semanal?',
      resposta:
          'Aceda ao separador "Agenda" e toque em "Semana" para ver todas as aulas da semana. Use "Dia" para ver apenas o dia actual.',
    ),
    _Faq(
      pergunta: 'Como alterar a minha senha?',
      resposta:
          'Vá a Perfil → Segurança → Alterar senha. Introduza a senha actual e defina uma nova com pelo menos 8 caracteres.',
    ),
    _Faq(
      pergunta: 'O que significa "Em Risco" no boletim?',
      resposta:
          'Significa que a sua média geral está abaixo de 10 valores (escala 0–20). Contacte o seu professor de acompanhamento para apoio.',
    ),
    _Faq(
      pergunta: 'Como activar notificações de notas?',
      resposta:
          'Aceda a Perfil → Notificações e active a opção "Notas e boletim".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _navy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajuda e FAQ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          const Text(
            'Perguntas frequentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Encontre respostas às dúvidas mais comuns.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            _faqs.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFaqItem(i),
            ),
          ),
          const SizedBox(height: 12),
          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildFaqItem(int i) {
    final expanded = _expandedIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = expanded ? null : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: expanded
              ? Border.all(color: _green.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _faqs[i].pergunta,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8E8E93),
                    size: 22,
                  ),
                ],
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text(
                  _faqs[i].resposta,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ainda tem dúvidas?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Entre em contacto com o nosso suporte.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Fale connosco'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.pergunta, required this.resposta});
  final String pergunta;
  final String resposta;
}
