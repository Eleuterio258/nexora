import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class ClassReportScreen extends StatefulWidget {
  const ClassReportScreen({super.key});

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  String _periodo = '1º Trimestre';

  static const _distribuicao = [
    _Faixa(label: '0–5', valor: 1),
    _Faixa(label: '6–9', valor: 3),
    _Faixa(label: '10–13', valor: 12),
    _Faixa(label: '14–17', valor: 9),
    _Faixa(label: '18–20', valor: 3),
  ];

  static const _alunosRisco = [
    _AlunoRisco(nome: 'Eduardo Cossa', media: '8.5'),
    _AlunoRisco(nome: 'Fátima Bila', media: '9.8'),
    _AlunoRisco(nome: 'Gilberto Mondlane', media: '7.2'),
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
        title: const Text(
          'Relatório · 10ª A',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: _green),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodos(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _OverviewCard(label: 'Aprovados', value: '24 / 28', color: _green)),
                  const SizedBox(width: 10),
                  Expanded(child: _OverviewCard(label: 'Reprovados', value: '4', color: Colors.redAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _OverviewCard(label: 'Média', value: '13.8', color: _navy)),
                ],
              ),
              const SizedBox(height: 24),
              _buildGrafico(),
              const SizedBox(height: 24),
              _buildAlunosRisco(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.table_chart_outlined, color: _green, size: 18),
                      label: const Text('Exportar Excel', style: TextStyle(color: _green, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: _green, size: 18),
                      label: const Text('Gerar PDF', style: TextStyle(color: _green, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodos() {
    final periodos = ['1º Trimestre', '2º Trimestre', 'Ano'];
    return Row(
      children: periodos.map((p) {
        final ativo = _periodo == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: ativo,
            onSelected: (_) => setState(() => _periodo = p),
            label: Text(p),
            selectedColor: _green,
            labelStyle: TextStyle(color: ativo ? Colors.white : _navy, fontWeight: FontWeight.w600),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: ativo ? _green : const Color(0xFFE5E5EA)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrafico() {
    final maximo = _distribuicao.map((f) => f.valor).reduce((a, b) => a > b ? a : b);
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição de Notas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _distribuicao.map((f) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${f.valor}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _navy),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: maximo == 0 ? 0 : (f.valor / maximo) * 100,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(f.label, style: const TextStyle(fontSize: 11, color: _grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlunosRisco() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Alunos em Risco · 3',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._alunosRisco.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.nome,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
                      ),
                    ),
                    Text(
                      a.media,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ],
      ),
    );
  }
}

class _Faixa {
  const _Faixa({required this.label, required this.valor});

  final String label;
  final int valor;
}

class _AlunoRisco {
  const _AlunoRisco({required this.nome, required this.media});

  final String nome;
  final String media;
}
