import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';

const _green = Color(0xFF00B87A);
const _navy  = Color(0xFF0D1B2A);
const _grey  = Color(0xFF8E8E93);

class ClassDetailTeacherScreen extends StatelessWidget {
  const ClassDetailTeacherScreen({super.key, required this.turma, required this.disciplina});

  final String turma;
  final String disciplina;

  static const _alunos = [
    _AlunoResume(nome: 'Ana Beatriz Silva',   media: 14.5, faltas: 1),
    _AlunoResume(nome: 'Bruno Machava',       media: 11.0, faltas: 3),
    _AlunoResume(nome: 'Carlos Nhaca',        media: 16.2, faltas: 0),
    _AlunoResume(nome: 'Diana Tembe',         media: 13.8, faltas: 2),
    _AlunoResume(nome: 'Eduardo Sitoe',       media: 9.5,  faltas: 5),
    _AlunoResume(nome: 'Fátima Cumbe',        media: 17.1, faltas: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(turma, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
                        Text(disciplina, style: const TextStyle(fontSize: 13, color: _grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.classReport),
                    icon: const Icon(Icons.bar_chart_rounded, color: _green),
                    tooltip: 'Relatório',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ActionChip(icon: Icons.how_to_reg_rounded, label: 'Presenças', onTap: () => Navigator.pushNamed(context, AppRoutes.attendance)),
                  const SizedBox(width: 10),
                  _ActionChip(icon: Icons.grade_rounded, label: 'Lançar Notas', onTap: () => Navigator.pushNamed(context, AppRoutes.gradeEntryStudents)),
                  const SizedBox(width: 10),
                  _ActionChip(icon: Icons.assignment_rounded, label: 'Tarefa', onTap: () => Navigator.pushNamed(context, AppRoutes.createTask)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Alunos (${_alunos.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: _alunos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _AlunoTile(aluno: _alunos[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: _green, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlunoTile extends StatelessWidget {
  const _AlunoTile({required this.aluno});
  final _AlunoResume aluno;

  Color get _mediaColor {
    if (aluno.media >= 14) return _green;
    if (aluno.media >= 10) return const Color(0xFFF59E0B);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: _green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aluno.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
                if (aluno.faltas > 0)
                  Text('${aluno.faltas} falta(s)', style: const TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _mediaColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              aluno.media.toStringAsFixed(1),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _mediaColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlunoResume {
  const _AlunoResume({required this.nome, required this.media, required this.faltas});
  final String nome;
  final double media;
  final int faltas;
}
