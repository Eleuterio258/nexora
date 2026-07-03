import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

enum _Presenca { presente, falta, justificada }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<int, _Presenca> _presencas = {};

  static final _alunos = List.generate(
    28,
    (i) => _Aluno(
      nome: _nomes[i % _nomes.length],
      numero: '${i + 1}'.padLeft(2, '0'),
    ),
  );

  int get _presentes => _presencas.values.where((p) => p == _Presenca.presente).length;
  int get _faltas => _presencas.values.where((p) => p == _Presenca.falta).length;
  int get _pendentes => _alunos.length - _presencas.length;

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
          'Marcar Presenças',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matemática · 10ª Classe A',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Seg 23 Jun · 08h00–09h30',
                          style: TextStyle(fontSize: 13, color: _grey),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sala 12',
                          style: TextStyle(fontSize: 12, color: _grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatusChip(label: 'Presentes: $_presentes', color: _green)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatusChip(label: 'Faltas: $_faltas', color: Colors.redAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatusChip(label: 'Pendentes: $_pendentes', color: _grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _marcarTodosPresentes,
                        icon: const Icon(Icons.done_all_rounded, color: _green, size: 18),
                        label: const Text(
                          'Marcar Todos Presentes',
                          style: TextStyle(color: _green, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _presencas.clear()),
                        child: const Text(
                          'Repor',
                          style: TextStyle(color: _grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _alunos.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (_, i) => _AlunoRow(
                  aluno: _alunos[i],
                  presenca: _presencas[i],
                  onChanged: (p) => setState(() => _presencas[i] = p),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Guardar Presenças',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _marcarTodosPresentes() {
    setState(() {
      for (var i = 0; i < _alunos.length; i++) {
        _presencas[i] = _Presenca.presente;
      }
    });
  }

  void _guardar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Presenças guardadas: $_presentes presentes, $_faltas faltas'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

class _AlunoRow extends StatelessWidget {
  const _AlunoRow({required this.aluno, required this.presenca, required this.onChanged});

  final _Aluno aluno;
  final _Presenca? presenca;
  final ValueChanged<_Presenca> onChanged;

  @override
  Widget build(BuildContext context) {
    final corFundo = presenca == _Presenca.falta
        ? Colors.red.withValues(alpha: 0.05)
        : presenca == _Presenca.justificada
            ? Colors.amber.withValues(alpha: 0.05)
            : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _green.withValues(alpha: 0.1),
            child: Text(
              aluno.nome.split(' ').map((p) => p[0]).take(2).join(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _green),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navy),
                ),
                Text(
                  'Nº ${aluno.numero}',
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
          _PresencaButton(
            label: 'P',
            cor: _green,
            selecionado: presenca == _Presenca.presente,
            onTap: () => onChanged(_Presenca.presente),
          ),
          const SizedBox(width: 6),
          _PresencaButton(
            label: 'F',
            cor: Colors.redAccent,
            selecionado: presenca == _Presenca.falta,
            onTap: () => onChanged(_Presenca.falta),
          ),
          const SizedBox(width: 6),
          _PresencaButton(
            label: 'J',
            cor: Colors.amber,
            selecionado: presenca == _Presenca.justificada,
            onTap: () => onChanged(_Presenca.justificada),
          ),
        ],
      ),
    );
  }
}

class _PresencaButton extends StatelessWidget {
  const _PresencaButton({required this.label, required this.cor, required this.selecionado, required this.onTap});

  final String label;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selecionado ? cor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selecionado ? cor : const Color(0xFFE5E5EA)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selecionado ? Colors.white : cor,
            ),
          ),
        ),
      ),
    );
  }
}

class _Aluno {
  const _Aluno({required this.nome, required this.numero});

  final String nome;
  final String numero;
}

const _nomes = [
  'Ana Beatriz Machava',
  'Bruno Silva Tembe',
  'Carlos Muianga',
  'Diana Nhamposse',
  'Eduardo Cossa',
  'Fátima Bila',
  'Gilberto Mondlane',
  'Helena Sitoe',
];
