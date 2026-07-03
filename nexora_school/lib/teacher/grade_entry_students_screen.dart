import 'package:flutter/material.dart';
import 'grade_entry_class_screen.dart' show Turma;

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class GradeEntryStudentsScreen extends StatefulWidget {
  const GradeEntryStudentsScreen({super.key, required this.turma});

  final Turma turma;

  @override
  State<GradeEntryStudentsScreen> createState() => _GradeEntryStudentsScreenState();
}

class _GradeEntryStudentsScreenState extends State<GradeEntryStudentsScreen> {
  final Map<int, String> _notas = {};

  static final _alunos = List.generate(
    28,
    (i) => _Aluno(
      nome: _nomes[i % _nomes.length],
      numero: '${i + 1}'.padLeft(2, '0'),
    ),
  );

  int get _lancadas => _notas.values.where((v) => v.isNotEmpty).length;

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
          'Notas · ${widget.turma.nome.split(' ').take(2).join(' ')} · ${widget.turma.disciplina}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
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
                  Row(
                    children: [
                      _Chip(label: 'Teste 2 · Trimestre 1', color: const Color(0xFFF0FDF4), textColor: _green),
                      const SizedBox(width: 8),
                      _Chip(label: 'Nota máx: 20', color: const Color(0xFFF5F5F7), textColor: _grey),
                      const SizedBox(width: 8),
                      _Chip(label: 'Lançadas: $_lancadas/${_alunos.length}', color: const Color(0xFFF0FDF4), textColor: _green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Pesquisar aluno...',
                              hintStyle: TextStyle(color: _grey, fontSize: 14),
                              icon: Icon(Icons.search_rounded, color: _grey, size: 22),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _preencherEmMassa,
                        child: const Text(
                          'Preencher em Massa',
                          style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _alunos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _AlunoRow(
                  aluno: _alunos[i],
                  nota: _notas[i] ?? '',
                  onChanged: (v) => setState(() => _notas[i] = v),
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E5EA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Guardar Rascunho',
                          style: TextStyle(color: _navy, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _publicar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Publicar Notas',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
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

  void _preencherEmMassa() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preencher em massa'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nota para todos os alunos'),
          onSubmitted: (v) {
            Navigator.pop(context);
            setState(() {
              for (var i = 0; i < _alunos.length; i++) {
                _notas[i] = v;
              }
            });
          },
        ),
      ),
    );
  }

  void _publicar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notas publicadas para ${widget.turma.disciplina} · ${widget.turma.nome}'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

class _AlunoRow extends StatelessWidget {
  const _AlunoRow({required this.aluno, required this.nota, required this.onChanged});

  final _Aluno aluno;
  final String nota;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final preenchido = nota.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
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
          SizedBox(
            width: 64,
            child: TextField(
              controller: TextEditingController(text: nota),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: preenchido ? _green : _grey,
              ),
              decoration: InputDecoration(
                hintText: '—',
                hintStyle: const TextStyle(color: _grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: const UnderlineInputBorder(borderSide: BorderSide(color: _green)),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _green)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _green, width: 2)),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (preenchido)
            const Icon(Icons.check_circle_rounded, color: _green, size: 20)
          else
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
        ],
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
