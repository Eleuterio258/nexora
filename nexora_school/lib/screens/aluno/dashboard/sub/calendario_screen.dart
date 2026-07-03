import 'package:flutter/material.dart';

const _navy = Color(0xFF0D1B2A);

class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  static const _eventos = [
    _Evento(dia: '24', mes: 'JUN', titulo: 'Prova de Matemática',           hora: '08:00', color: Color(0xFF00695C)),
    _Evento(dia: '27', mes: 'JUN', titulo: 'Entrega — Trabalho de História', hora: '23:59', color: Color(0xFF4527A0)),
    _Evento(dia: '30', mes: 'JUN', titulo: 'Fim do 2.° Trimestre',          hora: '—',     color: Color(0xFF1565C0)),
    _Evento(dia: '31', mes: 'JUN', titulo: 'Reunião de Pais e Mestres',     hora: '18:30', color: Color(0xFFE65100)),
    _Evento(dia: '05', mes: 'JUL', titulo: 'Início das Férias',             hora: '—',     color: Color(0xFF00B87A)),
    _Evento(dia: '15', mes: 'JUL', titulo: 'Publicação de Notas',           hora: '—',     color: Color(0xFF6750A4)),
    _Evento(dia: '04', mes: 'AGO', titulo: 'Regresso às Aulas',             hora: '—',     color: Color(0xFFF59E0B)),
    _Evento(dia: '18', mes: 'AGO', titulo: 'Início do 3.° Trimestre',       hora: '—',     color: Color(0xFF0277BD)),
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
            Text('Calendário', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            Text('Eventos académicos', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: _eventos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _EventoCard(item: _eventos[i]),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.item});
  final _Evento item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.mes, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.color)),
                Text(item.dia, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navy, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(item.titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
          ),
          const SizedBox(width: 10),
          Text(item.hora, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: item.color)),
        ],
      ),
    );
  }
}

class _Evento {
  const _Evento({required this.dia, required this.mes, required this.titulo, required this.hora, required this.color});
  final String dia, mes, titulo, hora;
  final Color color;
}
