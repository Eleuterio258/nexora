import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _red = Color(0xFFEF4444);

class FaltasScreen extends StatefulWidget {
  const FaltasScreen({super.key});

  @override
  State<FaltasScreen> createState() => _FaltasScreenState();
}

class _FaltasScreenState extends State<FaltasScreen> {
  _Filtro _filtro = _Filtro.todas;

  static const _faltas = [
    _FaltaData(
      data: '05/06/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '03/06/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '28/05/2025',
      disciplina: 'Geografia',
      icon: Icons.public_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '22/05/2025',
      disciplina: 'Química',
      icon: Icons.science_outlined,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '20/05/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '15/05/2025',
      disciplina: 'Educação Física',
      icon: Icons.directions_run_rounded,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '12/05/2025',
      disciplina: 'Geografia',
      icon: Icons.public_outlined,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '07/05/2025',
      disciplina: 'Química',
      icon: Icons.science_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '05/05/2025',
      disciplina: 'Física',
      icon: Icons.bolt_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '29/04/2025',
      disciplina: 'Língua Portuguesa',
      icon: Icons.menu_book_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '22/04/2025',
      disciplina: 'Educação Física',
      icon: Icons.directions_run_rounded,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '15/04/2025',
      disciplina: 'Geografia',
      icon: Icons.public_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '10/04/2025',
      disciplina: 'Língua Portuguesa',
      icon: Icons.menu_book_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '03/04/2025',
      disciplina: 'Química',
      icon: Icons.science_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '27/03/2025',
      disciplina: 'História',
      icon: Icons.history_edu_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '20/03/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.porJustificar,
    ),
    _FaltaData(
      data: '13/03/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.justificada,
    ),
    _FaltaData(
      data: '06/03/2025',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      status: _Status.justificada,
    ),
  ];

  List<_FaltaData> get _filtradas {
    return switch (_filtro) {
      _Filtro.todas => _faltas,
      _Filtro.porJustificar =>
        _faltas.where((f) => f.status == _Status.porJustificar).toList(),
      _Filtro.justificadas =>
        _faltas.where((f) => f.status == _Status.justificada).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = _faltas.length;
    final porJustificar = _faltas
        .where((f) => f.status == _Status.porJustificar)
        .length;
    final justificadas = total - porJustificar;
    final filtradas = _filtradas;

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
          'Faltas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSummary(total, justificadas, porJustificar),
          _buildFiltros(),
          Expanded(
            child: filtradas.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: filtradas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) =>
                        _buildFaltaCard(context, filtradas[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Resumo ─────────────────────────────────────────────────────────────────

  Widget _buildSummary(int total, int just, int porJust) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _StatChip(value: total, label: 'Total', color: _navy),
          const SizedBox(width: 10),
          _StatChip(value: just, label: 'Justificadas', color: _green),
          const SizedBox(width: 10),
          _StatChip(value: porJust, label: 'Por justificar', color: _red),
        ],
      ),
    );
  }

  // ── Filtros ────────────────────────────────────────────────────────────────

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: _Filtro.values.map((f) {
          final selected = f == _filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filtro = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? _green : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Card de falta ──────────────────────────────────────────────────────────

  Widget _buildFaltaCard(BuildContext context, _FaltaData f) {
    final isPorJust = f.status == _Status.porJustificar;
    final iconColor = isPorJust ? _red : _green;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(f.icon, color: iconColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.disciplina,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.data,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPorJust)
                GestureDetector(
                  onTap: () => _showJustificarSheet(context, f),
                  child: const Text(
                    'Justificar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _red,
                    ),
                  ),
                )
              else
                const Text(
                  'Justificada',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: _green.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sem faltas nesta categoria',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Continue assim!',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  // ── Sheet de justificação ──────────────────────────────────────────────────

  void _showJustificarSheet(BuildContext context, _FaltaData f) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Solicitar justificação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${f.disciplina}  ·  ${f.data}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _navy),
              decoration: InputDecoration(
                hintText: 'Descreva o motivo da falta...',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Justificação enviada com sucesso'),
                      backgroundColor: _green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Enviar pedido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }
}

// ── Enums e dados ─────────────────────────────────────────────────────────────

enum _Filtro {
  todas('Todas'),
  porJustificar('Por justificar'),
  justificadas('Justificadas');

  const _Filtro(this.label);
  final String label;
}

enum _Status { porJustificar, justificada }

class _FaltaData {
  const _FaltaData({
    required this.data,
    required this.disciplina,
    required this.icon,
    required this.status,
  });
  final String data;
  final String disciplina;
  final IconData icon;
  final _Status status;
}
