import 'package:flutter/material.dart';

const _navy  = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  int _filtroIndex = 0;

  static const _filtros = ['Todas', 'Notas', 'Comunicados', 'Tarefas', 'Horário'];

  static final _notificacoes = [
    _Notif(
      titulo: 'Nova nota em Matemática',
      corpo: 'Prof. Rafael lançou nota: 17 valores no Teste 2.',
      hora: '5 min atrás',
      lida: false,
      tipo: 'Notas',
      icon: Icons.calculate_outlined,
      color: Color(0xFF10B981),
    ),
    _Notif(
      titulo: 'Reunião de Pais',
      corpo: 'Sexta-feira, 27 Jun às 14h00 — Confirme presença.',
      hora: '1 hora atrás',
      lida: false,
      tipo: 'Comunicados',
      icon: Icons.groups_outlined,
      color: Color(0xFF6750A4),
    ),
    _Notif(
      titulo: 'Tarefa entregue',
      corpo: 'A sua ficha de Física foi enviada com sucesso.',
      hora: '2 horas atrás',
      lida: false,
      tipo: 'Tarefas',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF00B87A),
    ),
    _Notif(
      titulo: 'Prova de Química amanhã',
      corpo: 'Lembre-se: prova de Química amanhã às 08h00.',
      hora: '3 horas atrás',
      lida: false,
      tipo: 'Horário',
      icon: Icons.science_outlined,
      color: Color(0xFFEC4899),
    ),
    _Notif(
      titulo: 'Nova nota em Biologia',
      corpo: 'Profa. Maria João lançou nota: 18 valores.',
      hora: 'Ontem',
      lida: true,
      tipo: 'Notas',
      icon: Icons.eco_outlined,
      color: Color(0xFF06B6D4),
    ),
    _Notif(
      titulo: 'Comunicado da Direcção',
      corpo: 'Calendário de exames finais publicado no portal.',
      hora: 'Ontem',
      lida: true,
      tipo: 'Comunicados',
      icon: Icons.campaign_outlined,
      color: Color(0xFFEF4444),
    ),
    _Notif(
      titulo: 'Tarefa pendente',
      corpo: 'Entrega de Trabalho de História até 27 Jun às 23h59.',
      hora: '2 dias atrás',
      lida: true,
      tipo: 'Tarefas',
      icon: Icons.assignment_outlined,
      color: Color(0xFFF59E0B),
    ),
    _Notif(
      titulo: 'Aula cancelada',
      corpo: 'Aula de Inglês de quarta-feira cancelada. Sala 204.',
      hora: '3 dias atrás',
      lida: true,
      tipo: 'Horário',
      icon: Icons.event_busy_outlined,
      color: Color(0xFF6366F1),
    ),
    _Notif(
      titulo: 'Nova nota em Inglês',
      corpo: 'Prof. Carlos Santos lançou nota: 15 valores.',
      hora: '4 dias atrás',
      lida: true,
      tipo: 'Notas',
      icon: Icons.language_outlined,
      color: Color(0xFF8B5CF6),
    ),
  ];

  List<_Notif> get _filtradas {
    if (_filtroIndex == 0) return _notificacoes;
    final tipo = _filtros[_filtroIndex];
    return _notificacoes.where((n) => n.tipo == tipo).toList();
  }

  int get _naoLidas => _notificacoes.where((n) => !n.lida).length;

  void _marcarTodasLidas() => setState(() {
        for (final n in _notificacoes) {
          n.lida = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    final naoLidasFiltradas = filtradas.where((n) => !n.lida).toList();
    final lidasFiltradas    = filtradas.where((n) => n.lida).toList();

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notificações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            if (_naoLidas > 0)
              Text('$_naoLidas não lidas', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        actions: [
          if (_naoLidas > 0)
            TextButton(
              onPressed: _marcarTodasLidas,
              child: const Text('Marcar lidas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _green)),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _filtros.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _filtroIndex;
                return GestureDetector(
                  onTap: () => setState(() => _filtroIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _green : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      _filtros[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Lista
          Expanded(
            child: filtradas.isEmpty
                ? const Center(child: Text('Sem notificações', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      if (naoLidasFiltradas.isNotEmpty) ...[
                        _SectionLabel(label: 'Não lidas · ${naoLidasFiltradas.length}', dot: true),
                        ...naoLidasFiltradas.map((n) => _NotifTile(item: n, onTap: () => setState(() => n.lida = true))),
                      ],
                      if (lidasFiltradas.isNotEmpty) ...[
                        const _SectionLabel(label: 'Anteriores'),
                        ...lidasFiltradas.map((n) => _NotifTile(item: n)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Secção label ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.dot = false});
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          if (dot) ...[
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}

// ── Tile de notificação ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item, this.onTap});
  final _Notif item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
      onTap: onTap,
      child: Container(
        color: item.lida ? Colors.transparent : _green.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(width: 14),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.lida ? FontWeight.w500 : FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(item.hora, style: TextStyle(fontSize: 11, color: item.lida ? const Color(0xFFADB5BD) : _green)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.corpo,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(item.tipo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.color)),
                ],
              ),
            ),
            if (!item.lida) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    ),
        const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _Notif {
  _Notif({required this.titulo, required this.corpo, required this.hora, required this.lida, required this.tipo, required this.icon, required this.color});
  final String titulo, corpo, hora, tipo;
  bool lida;
  final IconData icon;
  final Color color;
}
