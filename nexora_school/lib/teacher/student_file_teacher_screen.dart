import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class StudentFileTeacherScreen extends StatefulWidget {
  const StudentFileTeacherScreen({
    super.key,
    required this.nome,
    required this.numero,
    required this.turma,
    required this.disciplina,
  });

  final String nome;
  final String numero;
  final String turma;
  final String disciplina;

  @override
  State<StudentFileTeacherScreen> createState() => _StudentFileTeacherScreenState();
}

class _StudentFileTeacherScreenState extends State<StudentFileTeacherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _notas = [
    _Nota(data: '15 Mar', tipo: 'Teste 1', valor: '16', tendencia: 0),
    _Nota(data: '28 Mar', tipo: 'Ficha', valor: '17', tendencia: 1),
    _Nota(data: '10 Abr', tipo: 'Teste 2', valor: '14', tendencia: -1),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: Text(
          widget.nome,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _green.withValues(alpha: 0.1),
                          child: Text(
                            widget.nome.split(' ').map((p) => p[0]).take(2).join(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _green),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.nome,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.turma} · Nº ${widget.numero}',
                          style: const TextStyle(fontSize: 13, color: _grey),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Turma de ${widget.disciplina}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PerformanceCard(
                          label: 'Média em Mat.',
                          value: '15.7',
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PerformanceCard(
                          label: 'Assiduidade',
                          value: '90%',
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PerformanceCard(
                          label: 'Tarefas',
                          value: '7/8',
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nota abaixo de 10 no Teste 2 — considere apoio adicional.',
                            style: TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: _green,
              indicatorWeight: 2.5,
              labelColor: _green,
              unselectedLabelColor: const Color(0xFFADB5BD),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Notas'),
                Tab(text: 'Presenças'),
                Tab(text: 'Tarefas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotasTab(),
                  const Center(child: Text('Presenças do aluno', style: TextStyle(color: _grey))),
                  const Center(child: Text('Tarefas do aluno', style: TextStyle(color: _grey))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Enviar Mensagem', style: TextStyle(color: _green)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Adicionar Nota', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotasTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        ..._notas.map((n) => _NotaRow(nota: n)),
        const SizedBox(height: 20),
        const Text(
          'Evolução',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _notas.map((n) {
              final valor = double.tryParse(n.valor) ?? 0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 32,
                    height: valor * 4,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(n.data, style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _grey),
          ),
        ],
      ),
    );
  }
}

class _NotaRow extends StatelessWidget {
  const _NotaRow({required this.nota});

  final _Nota nota;

  @override
  Widget build(BuildContext context) {
    final valor = double.tryParse(nota.valor) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          Text(nota.data, style: const TextStyle(fontSize: 12, color: _grey)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              nota.tipo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green),
            ),
          ),
          const Spacer(),
          Text(
            nota.valor,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valor >= 10 ? _green : Colors.redAccent),
          ),
          const SizedBox(width: 8),
          Icon(
            nota.tendencia == 1
                ? Icons.trending_up_rounded
                : nota.tendencia == -1
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
            color: nota.tendencia == 1
                ? _green
                : nota.tendencia == -1
                    ? Colors.redAccent
                    : _grey,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _Nota {
  const _Nota({required this.data, required this.tipo, required this.valor, required this.tendencia});

  final String data;
  final String tipo;
  final String valor;
  final int tendencia;
}
