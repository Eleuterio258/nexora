import 'package:flutter/material.dart';

const _navy = Color(0xFF0D1B2A);

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  static const _items = [
    _Noticia(titulo: 'Inscrições para o Desporto Escolar abertas',     data: '25/06/2025', tag: 'Desporto',  tagColor: Color(0xFF00695C)),
    _Noticia(titulo: 'Exposição de Arte — trabalhos do 3.° Trimestre', data: '22/06/2025', tag: 'Arte',      tagColor: Color(0xFF6750A4)),
    _Noticia(titulo: 'Calendário de exames finais publicado',           data: '20/06/2025', tag: 'Exames',    tagColor: Color(0xFFE65100)),
    _Noticia(titulo: 'Visita de estudo ao Museu Nacional',              data: '18/06/2025', tag: 'Eventos',   tagColor: Color(0xFF1565C0)),
    _Noticia(titulo: 'Reunião geral de pais — 31 de Junho',            data: '15/06/2025', tag: 'Reuniões',  tagColor: Color(0xFFF59E0B)),
    _Noticia(titulo: 'Olimpíadas de Matemática — inscrições abertas',  data: '10/06/2025', tag: 'Desporto',  tagColor: Color(0xFF00695C)),
    _Noticia(titulo: 'Novo horário do refeitório publicado',            data: '05/06/2025', tag: 'Avisos',    tagColor: Color(0xFF8E8E93)),
  ];

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notícias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            Text('Comunicados da escola', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _NoticiaCard(item: _items[i]),
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  const _NoticiaCard({required this.item});
  final _Noticia item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.tagColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
                const SizedBox(height: 4),
                Text(item.data, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.tagColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(item.tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.tagColor)),
          ),
        ],
      ),
    );
  }
}

class _Noticia {
  const _Noticia({required this.titulo, required this.data, required this.tag, required this.tagColor});
  final String titulo, data, tag;
  final Color tagColor;
}
